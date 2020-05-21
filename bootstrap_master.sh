#!/bin/bash
#

MYIPS=$(hostname --all-ip-addresses)
MYIP=$(echo "${MYIPS}" | grep "${MYSUBNET}.[0-9]*" --only-matching)
MYHOSTNAME=$(hostname --short)
MYAPI="${MYSUBNET}.254"

/bin/nc -z "${MYAPI}" 8443
if [ $? -eq 0 ]; then
  cat /vagrant/haproxy.cfg >>/etc/haproxy/haproxy.cfg
  systemctl restart haproxy keepalived

  echo "API server ${MYAPI} already online, lets join it"
  $(cat /vagrant/joinmaster.sh) --apiserver-advertise-address="${MYIP}"

  # Copy Kube admin config
  echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
  mkdir /home/vagrant/.kube
  cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown -R vagrant:vagrant /home/vagrant/.kube

  mkdir -p /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config

  exit 0
fi

cat /vagrant/haproxy.cfg >>/etc/haproxy/haproxy.cfg
systemctl restart haproxy keepalived

# Initialize Kubernetes
echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address="$MYIP" --control-plane-endpoint="${MYAPI}:8443" --pod-network-cidr="192.168.0.0/16"
sleep 60 # Give it some time

# Copy Kube admin config
echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Deploy flannel network
echo "[TASK 3] Deploy cni"
kubectl create -f https://docs.projectcalico.org/manifests/calico.yaml
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
sleep 60 # Give it some time

# Generate Cluster join command
echo "[TASK 4] Generate and save cluster join commands to /vagrant"
CERTKEY=$(openssl rand -hex 32)
kubeadm init phase upload-certs --upload-certs --certificate-key "${CERTKEY}"
kubeadm token create --print-join-command --certificate-key "${CERTKEY}" > /vagrant/joinmaster.sh
kubeadm token create --print-join-command > /vagrant/joinworker.sh

#!/bin/bash
#

sudo tee /etc/apt/apt.conf.d/proxy.conf <<EOF
Acquire {
  HTTP::proxy "http://10.178.6.31:3142/";
  HTTPS::proxy "http://10.178.6.31:3142/";
}
EOF

echo "[TASK 2] Install docker container engine"
apt-get install apt-transport-https gnupg-agent -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -
add-apt-repository "deb [arch=amd64] http://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install docker-ce containerd.io docker-ce-cli -y

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "registry-mirrors": ["http://10.178.6.31:5000"]
}
EOF

# Enable docker service
echo "[TASK 3] Enable and start docker service"
systemctl restart docker
systemctl enable docker

# add ccount to the docker group
usermod -aG docker vagrant

# Add sysctl settings
echo "[TASK 6] Add sysctl settings"
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Disable swap
echo "[TASK 7] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

# Install apt-transport-https pkg
echo "[TASK 8] Installing apt-transport-https pkg"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add -

# Add the kubernetes sources list into the sources.list directory
tee /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update

echo "[TASK 9] Install Kubernetes kubeadm, kubelet and kubectl"
sudo apt-get install kubelet kubeadm kubectl -y
sudo apt-mark hold kubelet kubeadm kubectl

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl start kubelet
systemctl enable kubelet

# Update vagrant user's bashrc file
tee -a /etc/environment <<EOF
TERM=xterm
EDITOR=vim
EOF

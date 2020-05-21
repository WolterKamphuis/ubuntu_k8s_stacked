#!/bin/bash
#

MYIPS=$(hostname --all-ip-addresses)
MYIP=$(echo "${MYIPS}" | grep "${MYSUBNET}.[0-9]*" --only-matching)
MYHOSTNAME=$(hostname --short)
MYAPI="${MYSUBNET}.254"

apt-get install keepalived -y
tee /etc/keepalived/keepalived.conf <<EOF
# Script used to check if the Kubernetes API is running
vrrp_script check_api {
    script "/bin/nc -zv localhost 6443"
    interval 2
    weight 2
}

vrrp_instance VI_1 {
    state MASTER
    interface enp0s8
    virtual_router_id 1
    priority 100
    advert_int 1
    nopreempt
    authentication {
        auth_type AH
        auth_pass ahpohdX9Seir
    }
    virtual_ipaddress {
        ${MYAPI}
    }
    track_script {
        check_api
    }
}
EOF

systemctl enable keepalived
systemctl stop keepalived

apt-get install haproxy -y
tee /etc/sysctl.d/99-haproxy.conf <<EOF
net.ipv4.ip_nonlocal_bind=1
EOF
sysctl --system

tee -a /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes
    bind ${MYAPI}:8443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
EOF

sudo systemctl enable haproxy
sudo systemctl stop haproxy

echo "    server ${MYHOSTNAME} ${MYIP}:6443 check fall 3 rise 2" >> /vagrant/haproxy.cfg

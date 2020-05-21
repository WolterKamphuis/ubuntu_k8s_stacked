## Multimaster-multiworker K8S Vagrant deployment

Training for my CKA exam, this Vagrant deployment will deploy a 3-master, 3-worker K8S cluster using Virtualbox.

There are two commands involved to deploy the cluster.

```bash
vagrant up
vagrant provision --provision-with bootstrap_k8s
```

The command `vagrant up` will setup the 6 nodes with Docker, kubeadm, kubectl etc

The second command will on the masters setup the load-balancers (haproxy and keepalived) and init the cluster on the first node. The other masters will join the first node.

On the workers the second command will just let them join the cluster.

This copy based on https://bitbucket.org/exxsyseng/k8s_centos/src/master/vagrant-provisioning/, I've added multimaster mode using load-balancers.
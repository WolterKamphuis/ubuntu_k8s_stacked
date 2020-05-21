# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["VAGRANT_NO_PARALLEL"] = "serial"

MYSUBNET = "172.24.0"
VAGRANTFILE_API_VERSION = "2"

system("
    if [ #{ARGV[0]} = 'up' ]; then
        echo 'Cleanup any files from the previous run'
        rm -vf ./joinmaster.sh ./joinworker.sh ./haproxy.cfg
    fi
")

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provision "bootstrap_all", type: "shell", path: "bootstrap_all.sh"

  # Kubernetes Master Servers
  (11..13).each do |ip|
    config.vm.define "kmaster-#{ip}" do |kmaster|
      kmaster.vm.box = "ubuntu/bionic64"
      kmaster.vm.box_check_update = false
      kmaster.vm.hostname = "kmaster-#{ip}"
      kmaster.vm.network "private_network", ip: "#{MYSUBNET}.#{ip}"
      kmaster.vm.provider "virtualbox" do |vb|
        vb.name = "kmaster-#{ip}"
        vb.memory = 2048
        vb.cpus = 2
      end
      kmaster.vm.provision "bootstrap_lb", type: "shell", path: "bootstrap_lb.sh", env: {"MYSUBNET": "#{MYSUBNET}"}
      kmaster.vm.provision "bootstrap_k8s", type: "shell", run: "never", path: "bootstrap_master.sh", env: {"MYSUBNET" => "#{MYSUBNET}"}
    end
  end

  # Kubernetes Worker Nodes
  (21..23).each do |ip|
    config.vm.define "kworker-#{ip}" do |kworker|
      kworker.vm.box = "ubuntu/bionic64"
      kworker.vm.box_check_update = false
      kworker.vm.hostname = "kworker-#{ip}"
      kworker.vm.network "private_network", ip: "#{MYSUBNET}.#{ip}"
      kworker.vm.provider "virtualbox" do |vb|
        vb.name = "kworker-#{ip}"
        vb.memory = 1024
        vb.cpus = 1
      end
      kworker.vm.provision "bootstrap_k8s", type: "shell", run: "never", path: "bootstrap_worker.sh"
    end
  end
end

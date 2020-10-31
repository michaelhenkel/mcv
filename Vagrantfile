# -*- mode: ruby -*-
# vi: set ft=ruby :

#require 'yaml'
require 'json'
#settings = YAML.load_file 'config.yaml'

settings = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'config.json')))

CLUSTERS = settings['CLUSTERS']
CLUSTERNODES = settings['CLUSTERNODES']


Vagrant.configure("2") do |config|

  config.vm.box = "centos/7"
  config.vm.provision "file", source: "C:\\Users\\toxicer\\wslssh\\id_rsa.pub", destination: "~/.ssh/me.pub"
  config.vm.provision "shell", inline: <<-SHELL
cat /home/vagrant/.ssh/me.pub >> /home/vagrant/.ssh/authorized_keys
cp -r /home/vagrant/.ssh /root
#yum update
#yum upgrade -y
  SHELL
  
  config.vm.define "router" do |router|
    router.vm.network "public_network", bridge: "WSL", auto_config: false, mac: "de:ad:be:ef:02:01"
    router.vm.provision "shell", inline: <<-SHELL
systemctl stop firewalld
systemctl mask firewalld
yum install -y iptables-services
systemctl enable iptables.service
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
cat <<-'EOF' > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE="eth0"
BOOTPROTO="static"
IPADDR="192.168.1.111"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.254"
DNS1="8.8.8.8"
ONBOOT="yes"
TYPE="Ethernet"
EOF
    SHELL
    (1..CLUSTERS).each do |cluster|
      router.vm.provision "shell", inline: <<-SHELL
iptables -A FORWARD -i eth0:#{cluster} -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth0:#{cluster} -m state --state RELATED,ESTABLISHED -j ACCEPT
service iptables save
cat <<-'EOF' > /etc/sysconfig/network-scripts/ifcfg-eth0:#{cluster}
DEVICE="eth0:#{cluster}"
BOOTPROTO="static"
IPADDR="10.0.#{cluster}.254"
NETMASK="255.255.255.0"
DNS1="8.8.8.8"
ONBOOT="yes"
TYPE="Ethernet"
EOF
      SHELL
    end
    router.vm.hostname = "router"
    router.vm.provider "hyperv" do |h|
      h.cpus = 1
      h.memory = 512
      h.vmname = "router"
    end

    router.vm.provision :shell do |shell|
      shell.privileged = true
      shell.inline = 'echo rebooting'
      shell.reboot = true
    end
  end

  (1..CLUSTERS).each do |cluster|
    (1..CLUSTERNODES).each do |i|
      config.vm.define "server#{cluster}#{i}" do |server|
        server.vm.provision "shell", inline: <<-SHELL
          echo "127.0.0.1 localhost" > /etc/hosts
          for c in {1..#{CLUSTERS}}
          do
            for cn in {1..#{CLUSTERNODES}}
            do
              echo "10.0.${c}.${cn} server${c}${cn}.cluster${c}.local server${c}${cn}" >> /etc/hosts
            done
          done        
        SHELL
        server.vm.network "public_network", bridge: "WSL", auto_config: false, mac: "de:ad:be:ef:01:#{cluster}#{i}"
        server.vm.hostname = "server#{cluster}#{i}"
        server.vm.provider "hyperv" do |h|
            h.cpus = 2
            h.memory = 10000
            h.vmname = "server#{cluster}#{i}"
        end
        server.vm.provision "shell", inline: <<-SHELL
cat <<-'EOF' > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE="eth0"
BOOTPROTO="static"
IPADDR="10.0.#{cluster}.#{i}"
NETMASK="255.255.255.0"
GATEWAY="10.0.#{cluster}.254"
DNS1="8.8.8.8"
ONBOOT="yes"
TYPE="Ethernet"
EOF
        SHELL
        server.vm.provision :shell do |shell|
          shell.privileged = true
          shell.inline = 'echo rebooting'
          shell.reboot = true
        end
      end
    end
  end
end

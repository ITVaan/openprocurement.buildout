# -*- mode: ruby -*-
# vi: set ft=ruby :

vagrant_user = "vagrant"

# "default" vm config
guest_ip = "192.168.100.1"
hostname = "op.local"

# code directories
code_share_host_path = "."
code_share_guest_path = "/vagrant/"

Vagrant.configure(2) do |config|
  config.vm.box = "prevoty/fedora-23"

  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 6543, host: 6543
  config.vm.network "forwarded_port", guest: 5984, host: 5984

  config.vm.hostname = hostname
  config.vm.network "private_network", ip: guest_ip

  # mount the host shared folder
  config.vm.synced_folder code_share_host_path, code_share_guest_path, mount_options: ["ro"]
  config.vm.synced_folder "share", "/srv/op"

  # set up private code
  if File.exist?("#{code_share_host_path}/deploy_op.sh")
    config.vm.provision "shell", path: "#{code_share_host_path}/deploy_op.sh"
  else
    config.vm.provision "shell", path: "https://raw.githubusercontent.com/gorserg/openprocurement.buildout/deploy_app/deploy_op.sh"
  end
  #
end

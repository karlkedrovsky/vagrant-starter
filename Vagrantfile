# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "trusty"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  config.vm.network :private_network, ip: "10.1.0.2"

  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
    vb.customize ["modifyvm", :id, "--name", "changeme"]
  end

  # This is a workaround to allow ssh agent forwarding to work during provisioning.
  # See https://github.com/mitchellh/vagrant/issues/1303
  config.vm.provision :shell do |shell|
    shell.inline = "touch $1 && chmod 0440 $1 && echo $2 > $1"
    shell.args = %q{/etc/sudoers.d/root_ssh_agent "Defaults    env_keep += \"SSH_AUTH_SOCK\""}
  end

  config.vm.provision :shell, :path => "provision_drupal.sh"

end

# Vagrant Provisioning Shell Scripts

These are some scripts I use to provision various different vagrant
boxes used for development. I like to have a seperate vm for each
project I work but they tend to be pretty similar so having a simple
shell provisioner just makes it easier to spin them up.

These scripts are meant to be used as a starting point - copy them to
a project specific folder and adjust as needed.

There are two common files that are included by the other provisioning
scripts:

- provision_settings.sh - This is intended to hold settings used by
  the provision.sh script that should not be checked into version
  control. Things like usernames and passwords for version control.
- provision_personal.sh - Provisioning steps that are unique to an
  individual. The one in this repo has the steps necessary to fetch my
  configuration files from github and set a different default shell.

Here's how I use these files.

1. Copy Vagrantfile, provision_drupal.sh, provision_settings.sh and
   provision_personal.sh to a new directory.
1. Edit Vagrantfile changing the hostname and IP address of the VM.
1. Optionally edit provision_settings.sh if I need to sensitive
   settings to the provision script.
1. Set whatever version control sysetm I'm using to ignore
   provision_settings.sh.
1. Edit provision.sh and update variable, etc.
1. Run "vagrant up".

There are three provision scripts so far for Drupal, Ruby and Node
development. All three are very much works in progress and the only
script I've used for "real work" is the Drupal version. The Ruby and
Node scripts are pretty basic and I've only used them for the odd
experiment or two.

## NFS Shares

Mounting nfs shares exported by the VM works without any additional
steps under OS X but under Linux you have to add something like the
following to /etc/fstab.

    10.1.0.14:/export/foo /home/karl/mount/foo nfs rw,noauto,user 0 0

In this case 10.1.0.14 is the ip of the VM, /export/foo is the
exported directory in the VM and /home/karl/mount/foo is the directory
on the host where the nfs share will be mounted. To mount the share
after the VM is started just run:

    mount /home/karl/mount/foo

## Livereload and Guard

I use [Guard](http://guardgem.org/) along with
[guard-livereload](https://github.com/guard/guard-livereload) running
in the VM and to get that to work you have to set up a tunnel from the
host to the VM. To set this up just run the following command on the
host.

    ssh -L 35729:127.0.0.1:35729 vagrant@guesthostname -N

The "vagrant" user's password is "vagrant". I also had to set the host
in the Guardfile so that it looks like this.

    guard 'livereload', host: '127.0.0.1' do
      ...
    end

A full example can be found in my
[Drupal start theme](https://github.com/karlkedrovsky/drupal-sass-starter).

## Site Creation and Deletion Scripts

There are two utility scripts that I wrote to automate the set up and
tear down of sites, mostly for testing and demo sites that will live
for a short time and then get deleted. Those two scripts are
createdrupalsite.sh and deletedrupalsite.sh.

If you plan on using them make sure you read and understand the
scripts first. They may do things to your server that you would really
rather not be done...

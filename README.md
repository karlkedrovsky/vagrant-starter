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

At this time the only provisioning script is the one I use for Drupal
projects.

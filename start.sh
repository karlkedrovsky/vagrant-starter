#!/bin/bash

echo "Starting the vm..."
vagrant up

# Check to see if there is a mount that already exists and unmount it
mount |grep 'MOUNT_NAME' >/dev/null
RC=$?
if [[ $RC == 0 ]]; then
  echo "Unmounting existing mount..."
  umount ~/mount/MOUNT_NAME
fi

echo "Creating nfs mount..."
if [[ ! -d ~/mount/MOUNT_NAME ]]; then
  mkdir ~/mount/MOUNT_NAME
fi
OS=`uname`
if [[ $OS == 'Linux' ]]; then
  mount ~/mount/MOUNT_NAME
else
  # assumes normal user can run mount (e.g. OS X)
  mount -t nfs MOUNT_NAME:/export/MOUNT_NAME ~/mount/MOUNT_NAME
fi

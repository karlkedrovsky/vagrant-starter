#!/bin/bash

# Check to see if there is a mount that already exists and unmount it
mount |grep 'MOUNT_NAME' >/dev/null
RC=$?
if [[ $RC == 0 ]]; then
  echo "Unmounting existing mount..."
  umount ~/mount/MOUNT_NAME
fi

echo "Stoping the vm..."
vagrant halt

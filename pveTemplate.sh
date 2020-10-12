#!/usr/bin/env bash

# Getting the required parameters
TEMPLATENAME=$1
TEMPLATEID=$2
IMAGE=$3

BASEMEMORY=256

if [ "$#" -lt "3" ]
    then echo "Missing Argument"
fi

echo "Generating template $1 with ID $2, with image from $3"

echo "Defining Template VM"
#qm create 9000 --name "$1" --memory $BASEMEMORY --net0 virtio,bridge=vmbr0

echo "Checking extension of image."
if [ "${IMAGE: -4}" == ".img" ]
    then
        echo "Changing extension of image to .qcow."
        NEWIMAGE=${IMAGE%.*}
        NEWIMAGE+=".qcow" 
        mv $IMAGE $NEWIMAGE
        echo "$IMAGE has been changed to $NEWIMAGE"
        IMAGE = $NEWIMAGE
fi

echo "Importing the image into Proxmox"
DISKNAME = $(qm importdisk $TEMPLATEID $IMAGE local-lvm)

echo "Configuring the Template VM to use the new Image"
qm set $TEMPLATEID --scsihw virtio-scsi-pci --scsi0 local-lvm:$DISKNAME

echo "Adding the Cloud-init image as the CD-Rom drive"
qm set $TEMPLATEID --ide2 local:lvm:cloudinit

echo "Setting the Template VM to run from the Cloud-init image only"
qm set $TEMPLATEID --boot c --bootdisk scsi0

echo "Setting the serial console"
qm set $TEMPLATEID --serial0 socket --vga serial0

echo "Generating the template"
qm template $TEMPLATEID

echo "Template $TEMPLATENAME with ID $TEMPLATEID has been generated, with image from $3"

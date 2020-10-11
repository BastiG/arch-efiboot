#!/bin/sh

LABEL="Arch Linux"

KERNEL="/vmlinuz-linux"
INITRD="initrd=\\initramfs-linux.img"
INITRD_FALLBACK="initrd=\\initramfs-linux-fallback.img"

EFIBOOTMGR=/usr/bin/efibootmgr

# Identify boot and root devices and partition UUIDs
ROOTPART=$(mount | grep " / " | cut -d " " -f 1)
PARTUUID=$(blkid ${ROOTPART} -s PARTUUID -o value)
BOOTPART=$(mount | grep " /boot " | cut -d " " -f 1)
BOOTDEV=${BOOTPART::-1}
BOOTPART=${BOOTPART: -1}

# List existing boot entries and remove them
ENTRIES=$(${EFIBOOTMGR} | grep "${LABEL}" | sed 's/^Boot\([0-9]*\).*/\1/')

while IFS= read -r ENTRY
do
    echo "Removing existing boot entry ${ENTRY}"
    ${EFIBOOTMGR} --bootnum ${ENTRY} --delete-bootnum --quiet
done <<< "${ENTRIES}"

# Create new boot entries
echo "Creating boot entries for ${LABEL} with /boot on ${BOOTDEV}${BOOTPART} and / on ${PARTUUID}"

${EFIBOOTMGR} --disk ${BOOTDEV} --part ${BOOTPART} --create --label "${LABEL} (fallback)" --loader ${KERNEL} --unicode "root=PARTUUID=${PARTUUID} rw ${INITRD_FALLBACK}" --quiet
${EFIBOOTMGR} --disk ${BOOTDEV} --part ${BOOTPART} --create --label "${LABEL}" --loader ${KERNEL} --unicode "root=PARTUUID=${PARTUUID} rw ${INITRD}" --quiet

echo -e "\nPost-setup state:\n"

${EFIBOOTMGR}


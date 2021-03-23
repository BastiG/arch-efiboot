#!/bin/sh

LABEL="Arch Linux"
LABEL_FALLBACK="${LABEL} (Fallback)"

KERNEL="/vmlinuz-linux"
INITRD="initrd=\\initramfs-linux.img"
INITRD_FALLBACK="${INITRD%.*}-fallback.${INITRD##*.}"

EFIBOOTMGR=/usr/bin/efibootmgr

if [ ! -f "${EFIBOOTMGR}" ]
then
    pacman -S efibootmgr
fi

# Identify boot and root devices and partition UUIDs
ROOTPART=$(findmnt -fno SOURCE /)
PARTUUID=$(blkid -s PARTUUID -o value ${ROOTPART})

BOOTPART=$(findmnt -fno SOURCE /boot)
BOOTDEV=${BOOTPART::-1}
BOOTPART=${BOOTPART: -1}

# List existing boot entries and remove them
ENTRIES=$(${EFIBOOTMGR} | grep -e "${LABEL}\|${LABEL_FALLBACK}" | sed -r 's/^Boot\([0-9]*\).*/\1/')

while IFS= read -r ENTRY
do
    echo "Removing existing boot entry ${ENTRY}"
    ${EFIBOOTMGR} --bootnum ${ENTRY} --delete-bootnum --quiet
done <<< "${ENTRIES}"

# Create new boot entries
echo "Creating boot entries for ${LABEL} with /boot on ${BOOTDEV}${BOOTPART} and / on ${PARTUUID}"

${EFIBOOTMGR} --disk ${BOOTDEV} --part ${BOOTPART} --create --label "${LABEL_FALLBACK}" --loader ${KERNEL} --unicode "root=PARTUUID=${PARTUUID} rw ${INITRD_FALLBACK}" --quiet
${EFIBOOTMGR} --disk ${BOOTDEV} --part ${BOOTPART} --create --label "${LABEL}" --loader ${KERNEL} --unicode "root=PARTUUID=${PARTUUID} rw ${INITRD}" --quiet

echo -e "\nPost-setup state:\n"

${EFIBOOTMGR}


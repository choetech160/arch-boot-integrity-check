
#!/bin/bash

# Set strict error handling
set -euo pipefail


# Define color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
local color="$1"
local message="$2"
echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
command -v "$1" >/dev/null 2>&1
}

# Check for required tools
check_requirements() {
local required_tools=("gpg" "ykman")
for tool in "${required_tools[@]}"; do
if ! command_exists "$tool"; then
print_color "$RED" "Error: $tool is not installed. Please install it and run this script again."
exit 1
fi
done
}

# Function to set up GPG with YubiKey
setup_gpg_yubikey() {
print_color "$YELLOW" "Setting up GPG with YubiKey..."

# Check if YubiKey is inserted
if ! ykman list | grep -q "YubiKey"; then
print_color "$RED" "Error: YubiKey not detected. Please insert your YubiKey and try again."
exit 1
fi

# Generate a new GPG key on the YubiKey
print_color "$YELLOW" "Generating a new GPG key on your YubiKey. Follow the prompts..."
gpg --card-edit
print_color "$GREEN" "GPG key generated successfully."
}

# Function to create a detached signature of the boot partition
create_boot_signature() {
local boot_partition="/dev/nvme0n1p2"
local signature_file="/root/boot_partition.sig"

print_color "$YELLOW" "Creating a detached signature of the boot partition..."

# Get the GPG key ID from the YubiKey
local key_id=$(gpg --card-status | grep "General key info" -A 2 | tail -n 1 | awk '{print $NF}')

# Create the detached signature
sudo dd if="$boot_partition" bs=1M | gpg --detach-sign --default-key "$key_id" >"$signature_file"

print_color "$GREEN" "Boot partition signature created at $signature_file"
}

# Function to create the boot verification script
create_verify_script() {
local verify_script="/usr/local/bin/bootverify"

print_color "$YELLOW" "Creating boot verification script..."

cat <<EOF | sudo tee "$verify_script" >/dev/null
#!/bin/bash

BOOT_PARTITION="/dev/nvme0n1p2"
SIGNATURE_FILE="/root/boot_partition.sig"

# Verify the signature
if gpg --verify "\$SIGNATURE_FILE" <(dd if=\$BOOT_PARTITION bs=1M); then
echo "Boot partition integrity verified."
exit 0
else
echo "Boot partition integrity check failed. Possible tampering detected."
exit 1
fi
EOF

sudo chmod +x "$verify_script"
print_color "$GREEN" "Boot verification script created at $verify_script"
}

# Function to create initramfs hook
create_initramfs_hook() {
local hook_file="/etc/initcpio/hooks/bootverify"

print_color "$YELLOW" "Creating initramfs hook..."

cat <<EOF | sudo tee "$hook_file" >/dev/null
#!/bin/ash

run_hook() {
modprobe -a -q dm-crypt >/dev/null 2>&1
[ "\${quiet}" = "y" ] && CSQUIET=">/dev/null"

# Verify boot partition
if /bin/bootverify; then
echo "Boot partition verified. Proceeding with decryption."
else
echo "Boot partition verification failed. Stopping boot process."
exit 1
fi
}
EOF

sudo chmod +x "$hook_file"
print_color "$GREEN" "Initramfs hook created at $hook_file"
}

# Function to create initramfs install file
create_initramfs_install() {
local install_file="/etc/initcpio/install/bootverify"

print_color "$YELLOW" "Creating initramfs install file..."

cat <<EOF | sudo tee "$install_file" >/dev/null
#!/bin/bash

build() {
add_binary /usr/local/bin/bootverify
add_binary gpg
add_file /root/boot_partition.sig
add_file /root/.gnupg/pubring.kbx
add_file /root/.gnupg/trustdb.gpg
}

help() {
cat <<HELPEOF
This hook verifies the integrity of the boot partition using GPG and YubiKey.
HELPEOF
}
EOF

sudo chmod +x "$install_file"
print_color "$GREEN" "Initramfs install file created at $install_file"
}

# Function to update mkinitcpio.conf
update_mkinitcpio_conf() {
print_color "$YELLOW" "Updating mkinitcpio.conf..."

sudo sed -i 's/^HOOKS=.*/& bootverify/' /etc/mkinitcpio.conf
print_color "$GREEN" "mkinitcpio.conf updated"
}

# Function to regenerate initramfs
regenerate_initramfs() {
print_color "$YELLOW" "Regenerating initramfs..."

sudo mkinitcpio -P
print_color "$GREEN" "Initramfs regenerated"
}

# Main execution
main() {
print_color "$YELLOW" "Starting secure boot setup with YubiKey..."

check_requirements
setup_gpg_yubikey
create_boot_signature
create_verify_script
create_initramfs_hook
create_initramfs_install
update_mkinitcpio_conf
regenerate_initramfs

print_color "$GREEN" "Secure boot setup complete!"
print_color "$YELLOW" "Please ensure your bootloader is configured to use the new initramfs."
print_color "$YELLOW" "Remember to update the boot partition signature after any changes to the boot partition."
}

# Run the main function
main
bin/bash
BOOT_PARTITION="/dev/nvme0n1p2"
# MOUNT_POINT="/mnt/boot"
MOUNT_POINT="/boot"
HASH_FILE="/root/boot_hash"
CHALLENGE_FILE="/root/challenge"

mkdir -p $MOUNT_POINT
mount $BOOT_PARTITION $MOUNT_POINT

# CURRENT_HASH=$(find /mnt/boot -type f -exec sha256sum {} \; >/tmp/check_boot)
CURRENT_HASH=$(find $MOUNT_POINT -type f -print0 | sort -z | xargs -0 sha256sum >/tmp/check_boot)
# CURRENT_HASH=$(sha256sum "$MOUNT_POINT" | awk '{print $1}')
# read

while IFS= read -r line; do
if ! grep -q "$line" /root/boot_hash; then
echo "Mismatch found: $line"
fi
done </tmp/check_boot

if diff /tmp/check_boot /root/boot_hash; then
echo "Boot partition integrity verified"
else
echo "Boot partition WRONG"
fi
umount $MOUNT_POINT
echo "Partition unmounted"
#
# if [ "$CURRENT_HASH" != "$STORED_HASH" ]; then
#   echo "Boot partition integrity check failed"
#   exit 1
# fi


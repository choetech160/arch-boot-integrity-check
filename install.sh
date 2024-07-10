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
  local required_tools=("ykman", "ykchalresp", "openssl")
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
  local INITCPIO_HOOKS_DIR="/etc/initcpio/hooks/"

  print_color "$YELLOW" "Copying boot verification script to $INITCPIO_HOOKS_DIR"
  sudo bash -c mv ./hooks/integrity_check_script $INITCPIO_HOOKS_DIR

  sudo chmod +x "$INITCPIO_HOOKS_DIR/integrity_check_script"
  print_color "$GREEN" "Boot verification scripts copied to $INITCPIO_HOOKS_DIR"
}

# Function to create initramfs hook
create_initramfs_hook() {
  local INITCPIO_HOOKS_DIR="/etc/initcpio/hooks/"

  print_color "$YELLOW" "Creating initramfs hook..."
  sudo bash -c mv ./hooks/integrity_check $INITCPIO_HOOKS_DIR

  sudo chmod +x "$INITCPIO_HOOKS_DIR/integrity_check"
  print_color "$GREEN" "Initramfs hook created at $INITCPIO_HOOKS_DIR"
}

# Function to create initramfs install file
create_initramfs_install() {
  local INITCPIO_INSTALL_DIR="/etc/initcpio/install/bootverify"

  print_color "$YELLOW" "Creating initramfs install file..."
  sudo bash -c mv ./install/integrity_check $INITCPIO_INSTALL_DIR

  sudo chmod +x "$install_file"
  print_color "$GREEN" "Initramfs install file created at $INITCPIO_INSTALL_DIR"
}

# Function to update mkinitcpio.conf
update_mkinitcpio_conf() {
  print_color "$YELLOW" "Updating mkinitcpio.conf..."

  sudo sed -i 's/^HOOKS=.*/& integrity_check/' /etc/mkinitcpio.conf
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
  # setup_gpg_yubikey
  # create_boot_signature
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

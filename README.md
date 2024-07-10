# arch-boot-integrity-check
Scripts and configuration files to have an integrity check on /boot before the decryption of your main filesystem

## Installation
1. Clone this repo
```bash
git clone https://github.com/choetech160/arch-boot-integrity-check
cd arch-boot-integrity-check
```

2. Run the installation script as root
```bash
sudo ./install.sh
```


3. Follow the prompts and instructions during installation.

4. Reboot your system after installation is complete.

## Files

- `install.sh`: Main installation script
- `generate_hashes.sh`: Script to generate system hashes for integrity checks
- `integrity-check.sh`: Boot-time integrity check script

## Note

This setup assumes you have already installed Arch Linux with disk encryption. Please ensure your system meets these prerequisites before running the installation script.
Going through the scripts is always a good idea before they get pepper sprayed across your installation
FILES WILL BE MOVED TO APPROPRIATE LOCATIONS


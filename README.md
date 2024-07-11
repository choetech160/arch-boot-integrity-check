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


## Caveats and Security Considerations

1. Physical access: This system does not protect against physical access to the machine. An attacker with physical access could potentially bypass or disable the integrity checks.

2. YubiKey dependency: The system relies on the YubiKey for verification. If the YubiKey is lost or damaged, you may lose access to your system.

3. False positives: Legitimate updates to the boot partition will cause the integrity check to fail until the hashes are updated.

4. No encryption: This system verifies integrity but does not provide encryption for the boot partition.

5. Limited scope: The system only verifies the boot partition, not the entire system.

## Good Practices and Thumbs Up in InfoSec

1. Two-factor authentication: Using a YubiKey adds a physical factor to the boot process, enhancing security.

2. Integrity verification: Checking file hashes helps detect unauthorized modifications to critical system files.

3. Challenge-response mechanism: The use of a challenge-response system with the YubiKey adds an extra layer of security.

4. Principle of least privilege: The scripts and files are owned by root and have restricted permissions.

5. Transparency: The system provides clear feedback during the boot process, allowing the user to understand what's happening.

6. Fail-secure: If any part of the verification fails, the boot process is halted, preventing potential compromise. You can always decrypt your drive after and boot normally.

Remember, while this system adds a layer of security, it should be part of a comprehensive security strategy, including full-disk encryption, regular updates, and good operational security practices.


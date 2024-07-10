# #!/bin/bash
#
# # Define color codes
# RED='\033[38;2;255;0;0m'      # Pure red
# GREEN='\033[38;2;0;255;0m'    # Pure green
# YELLOW='\033[38;2;255;255;0m' # Yellow
# NC='\033[0m'                  # No Color
# echo -en "${GREEN}Generating system hashes...   "
#
# # Start spinner
# (
#   while :; do
#     # You can switch between the spinners, just comment/uncomment the right for loop
#     #for X in '•     ' ' •    ' '  •   ' '   •  ' '    • ' '     •' '    • ' '   •  ' '  •   ' ' •    '; do
#     #    echo -en "\b\b\b\b\b\b$X"
#     for X in '┤' '┘' '┴' '└' '├' '┌' '┬' '┐'; do
#       echo -en "${YELLOW}\b$X"
#       sleep 0.1
#     done
#   done
# ) &
# SPINNER_PID=$!
# mkdir -p /mnt/esp
# mount /dev/nvme0n1p1 /mnt/esp
# find /mnt/esp -type f -exec sha256sum {} \; >/mnt/esp/esp_hashes.txt
# umount /mnt/esp
# # Generate hashes
# #find /bin /sbin /lib /lib64 /etc /run /root /sys /tmp /var -type f -exec sha256sum {} \; >/root/system_hashes.txt 2>/dev/null
# #find /boot -type f -exec sha256sum {} \; >/boot/system_hashes.txt
# # Use file attributes (like immutable bit)
# # Stop spinner
# kill $SPINNER_PID
# wait $SPINNER_PID 2>/dev/null
# # echo -en "\033[2K\r"
#
# echo -e "\n${GREEN}✓ System hashes generated successfully.${NC}"
#
# challenge=$(head -c 64 /dev/urandom | xxd -p -c 64)
#
# echo -e "\n${YELLOW}***************************************"
# echo -e "* INSERT YOUR YUBIKEY NOW             *"
# echo -e "* PRESS <ENTER> ONCE DONE             *"
# echo -e "***************************************"
#
# # Start spinner
# {
#   while :; do
#     for X in '•     ' ' •    ' '  •   ' '   •  ' '    • ' '     •' '    • ' '   •  ' '  •   ' ' •    '; do
#       echo -en "\r${YELLOW}*               $X                *${NC}"
#       sleep 0.1
#     done
#   done
# } &
# SPINNER_PID=$!
#
# # Wait for user input
# read -s -r
#
# # Stop spinner
# kill $SPINNER_PID
# wait $SPINNER_PID 2>/dev/null
#
# # echo -e "\n${YELLOW}***************************************${NC}"
# echo -e "\n${YELLOW}***************************************"
# echo "* TOUCH YOUR YUBIKEY NOW              *"
# echo -n "***************************************"
#
# challenge=$(head -c 64 /dev/urandom | xxd -p -c 64)
# response=""
# timeout_counter=0
# max_timeout=30
# while [ -z "$response" ] && [ $timeout_counter -lt $max_timeout ]; do
#   printf "\r* Time remaining: %2ds               *" $((max_timeout - timeout_counter))
#   response=$(ykchalresp -2 -x "$challenge" 2>/dev/null | tr -d '\n')
#   if [ -n "$response" ]; then
#     printf "\r${GREEN}* ✓ YubiKey touched!                  *"
#     break
#   fi
#   sleep 1
#   ((timeout_counter++))
# done
# # while [ -z "$response" ] && [ $timeout_counter -lt $max_timeout ]; do
# # 	printf "\r* Time remaining: %2ds               *" $((max_timeout - timeout_counter))
# # 	response=$(ykchalresp -2 -x "$challenge" 2>/dev/null | tr -d '\n')
# # 	if [ -n "$response" ]; then
# # 		printf "\r* YubiKey touched!                    *"
# # 		break
# # 	fi
# # 	sleep 1
# # 	((timeout_counter++))
# # done
#
# echo -e "${YELLOW}\n***************************************${NC}"
#
# if [ $? -eq 124 ]; then
#   echo -e "${RED}✗ YubiKey timed out. Please try again.${NC}"
#   exit 1
# fi
#
# if [ -z "$response" ]; then
#   echo -e "${RED}✗ No response from YubiKey. Please try again.${NC}"
#   exit 1
# fi
#
# echo "$challenge:$response" >/root/challenge_response.txt
# echo -e "${GREEN}✓ YubiKey response successfully recorded.${NC}"

# In /root/generate_hashes.sh

# Define color codes
RED='\033[38;2;255;0;0m'      # Pure red
GREEN='\033[38;2;0;255;0m'    # Pure green
YELLOW='\033[38;2;255;255;0m' # Yellow
NC='\033[0m'                  # No Color

echo -en "${GREEN}Generating system hashes...   \n"
INTEGRITY_DIR="/etc/boot_integrity"
BOOT_DIR="/boot"
TOKEN_FILE="$INTEGRITY_DIR/boot_token.enc"
CHALLENGE_FILE="$INTEGRITY_DIR/challenge"
SALT_FILE="$INTEGRITY_DIR/salt.txt"
HASH_FILE="$INTEGRITY_DIR/boot_hash" #"/root/boot_hash"
# SIGNATURE_FILE="/root/boot_hash.sig"
# GPG_KEY_ID="3632B93C91353B30"

sudo mkdir -p $INTEGRITY_DIR
sudo chown root:root $INTEGRITY_DIR
sudo chmod 700 $INTEGRITY_DIR

#generate a random token
# boot_token=$(head -c 32 /dev/urandom | base64)

# Encrypt the token using Yubikey
# echo -n "$boot_token" | ykman openpgp encrypt -o /tmp/boot_token.enc
# sudo mv /tmp/boot_token.enc $TOKEN_FILE

# For grubx64.efi3632B93C91353B30
# dont need to check this as this is usually not necessary for the integrity check
# sha256sum $BOOT_DIR/efi/EFI/GRUB/grubx64.efi >/root/grubx64_efi_hash
sudo bash -c '
BOOT_DIR="'$BOOT_DIR'"
HASH_FILE="'$HASH_FILE'"
rm "$HASH_FILE"
while IFS= read -r -d "" file; do
  sha256sum "$file" >> "$HASH_FILE"
done < <(find "$BOOT_DIR" -type f ! -name "*.img" ! -path "*/efi/*" -print0)
echo "$(dd if=$BOOT_DIR/initramfs-linux-fallback.img bs=1M count=1 2>/dev/null | sha256sum | cut -d" " -f1)  $BOOT_DIR/initramfs-linux-fallback.img" >> "$HASH_FILE"
echo "$(dd if=$BOOT_DIR/initramfs-linux.img bs=1M count=1 2>/dev/null | sha256sum | cut -d" " -f1)  $BOOT_DIR/initramfs-linux.img" >> "$HASH_FILE"
'

boot_token=$(head -c 32 /dev/urandom | base64)      # gen a random boot token
challenge=$(head -c 64 /dev/urandom | xxd -p -c 64) # gen a random challenge for the yubikey
salt=$(head -c 16 /dev/urandom | xxd -p -c 32)      # gen a random salt for pbkdf2

echo -e "\n${YELLOW}***************************************"
echo -e "*       INSERT YOUR YUBIKEY NOW       *"
echo -e "*       PRESS <ENTER> ONCE DONE       *"
echo -e "***************************************"
read
# echo -e "${YELLOW}Touch your YubiKey now...${NC}"
response=$(timeout 15 ykchalresp -2 -x "$challenge")
if [ $? -eq 124 ]; then
  echo -e "${RED}✗ YubiKey timed out. Integrity check failed.${NC}"
  sleep 5
  exit 1
elif [ -z "$response" ]; then
  echo -e "${RED}✗ No response from YubiKey. Integrity check failed.${NC}"
  sleep 5
  exit 1
fi
# Derive a 256-bit key from yubikey response using PBKDF2
# key=$(echo -n "$response" | openssl dgst -sha256 -binary -pbkdf2 -iter 100000 -salt "$salt" | xxd -p -c 64)
key=$(echo -n "${response}${salt}" | openssl dgst -sha256 -binary | xxd -p -c 64)
# Generate a random IV
iv=$(openssl rand -hex 16)

# Encrypt the boot token
encrypted_token=$(echo -n "$boot_token" | openssl enc -aes-256-cbc -base64 -K "$key" -iv "$iv")

# save the challenge salt, IV & encrypted token
sudo bash -c "echo $challenge >$CHALLENGE_FILE"
sudo bash -c "echo $salt >$SALT_FILE"
sudo bash -c "echo $iv:$encrypted_token >$TOKEN_FILE"
sudo bash -c "cat $HASH_FILE <(echo -n $boot_token) | sha256sum > $INTEGRITY_DIR/integrity_hash"

echo -e "${GREEN}✗ Boot integrity token generated and encrypted.\n  Initial boot hash created.${NC}"

#!/usr/bin/env bash

# Variables
imageref="$(jq -r '."image-ref"' </usr/share/ublue-os/image-info.json)"
imageref="${imageref##*://}"
imagetag="$(jq -r 'if ."image-branch" then ."image-branch" else ."image-tag" end' </usr/share/ublue-os/image-info.json)"
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Secureboot Key Fetch
mkdir -p /run/install/repo
curl -Lo /run/install/repo/sb_pubkey.der "$sbkey"
# Signed Images
cat <<EOF >>/usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $imageref:$imagetag
%end
EOF

# Enroll Secureboot Key
cat <<EOF >>/usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/run/install/repo/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
	echo "EFI mode not detected. Skipping key enrollment."
	exit 0
fi

if [[ ! -f "\$SECUREBOOT_KEY" ]]; then
	echo "Secure boot key not provided: \$SECUREBOOT_KEY"
	exit 0
fi

SYS_ID="\$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":\$SYS_ID:" ]]; then
	echo "Steam Deck hardware detected. Skipping key enrollment."
	exit 0
fi

mokutil --timeout -1 || :
echo -e "\$ENROLLMENT_PASSWORD\n\$ENROLLMENT_PASSWORD" | mokutil --import "\$SECUREBOOT_KEY" || :
%end
EOF

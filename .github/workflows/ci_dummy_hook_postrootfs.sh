#!/usr/bin/env bash

zypper addrepo --non-interactive -y "https://download.opensuse.org/repositories/home:/Microwave:/anaconda/openSUSE_Tumbleweed/home:Microwave:anaconda.repo"
zypper install install -y anaconda-live MozillaFirefox

if [[ "${HIDE_SPOKE:-}" ]]; then
    # Hide Root Spoke
    cat <<EOF >>/etc/anaconda/conf.d/anaconda.conf
[User Interface]
hidden_spokes =
    PasswordSpoke
EOF
fi

tee /etc/anaconda/profile.d/opensuse-tumbleweed.conf <<'EOF'
# Anaconda configuration file for openSUSE Tumbleweed

[Profile]
# Define the profile.
profile_id = opensuse-tumbleweed

[Profile Detection]
# Match os-release values
os_id = opensuse-tumbleweed

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = opensuse
menu_auto_hide = False

[Storage]
file_system_type = ext4
default_partitioning =
    /     (min 5 GiB, max 70 GiB)
    /var  (min 5 GiB)

[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/opensuse.css
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
	SubscriptionSpoke
hidden_webui_pages =
    anaconda-screen-accounts
	root-password

[Localization]
use_geolocation = False
EOF

# Default Kickstart
cat <<EOF >>/usr/share/anaconda/interactive-defaults.ks
bootc --source-imgref=registry:ghcr.io/micro856/opensuse-bootc:latest
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
EOF

# Signed Images
cat <<EOF >>/usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ghcr.io/micro856/opensuse-bootc:latest
%end
EOF

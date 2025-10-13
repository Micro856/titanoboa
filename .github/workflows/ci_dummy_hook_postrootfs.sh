#!/usr/bin/env bash

# Variables
imageref="$(jq -r '."image-ref"' </usr/share/ublue-os/image-info.json)"
imageref="${imageref##*://}"
imagetag="$(jq -r 'if ."image-branch" then ."image-branch" else ."image-tag" end' </usr/share/ublue-os/image-info.json)"
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Secureboot Key Fetch
mkdir -p /run/install/repo
curl -Lo /run/install/repo/sb_pubkey.der "$sbkey"

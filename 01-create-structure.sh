#!/usr/bin/env bash

set -euo pipefail

# Make sure the script is being run from the repository root.
if [[ ! -d ".git" ]]; then
	echo "Error: no .git directory found."
	echo "Run this script from the root of the nix-homelab repository."
	exit 1
fi

echo "Creating NixOS homelab repository structure..."

mkdir -p hosts/homelab
mkdir -p modules/services

touch flake.nix
touch hosts/homelab/default.nix
touch modules/base.nix
touch modules/networking.nix
touch modules/ssh.nix
touch modules/users.nix
touch modules/storage.nix
touch modules/containers.nix

touch modules/services/default.nix

echo
echo "Created structure:"
find hosts modules -print | sort

echo
echo "Created flake.nix"
echo
echo "Note: hardware-configuration.nix was not created."
echo "It must later be generated on the actual homelab PC."
EOF

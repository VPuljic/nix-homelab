#!/usr/bin/env bash

set -euo pipefail

if [[ ! -d ".git" ]]; then
	echo "Error: no .git directory found."
	echo "Run this script from the root of the nix-homelab repository."
	exit 1
fi

required_files=(
	"flake.nix"
	"hosts/homelab/default.nix"
	"modules/base.nix"
	"modules/networking.nix"
	"modules/ssh.nix"
	"modules/users.nix"
	"modules/storage.nix"
	"modules/containers.nix"
	"modules/services/default.nix"
)

for file in "${required_files[@]}"; do
	if [[ ! -e "$file" ]]; then
		echo "Error: required file does not exist: $file"
		echo "Run ./01-create-structure.sh first."
		exit 1
	fi
done

echo "Writing flake.nix..."

cat >flake.nix <<'NIX'
{
  description = "Declarative NixOS homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { nixpkgs, ... }:
    {
      nixosConfigurations.homelab = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./hosts/homelab
        ];
      };
    };
}
NIX

echo "Writing hosts/homelab/default.nix..."

cat >hosts/homelab/default.nix <<'NIX'
{ lib, ... }:

{
  imports = [
    # Add this after installing NixOS on the actual homelab PC:
    # ./hardware-configuration.nix

    ../../modules/base.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/storage.nix
    ../../modules/containers.nix
    ../../modules/services
  ];

  networking.hostName = "homelab";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Keep this value at the version used for the first installation.
  system.stateVersion = "26.05";
}
NIX

echo "Writing modules/base.nix..."

cat >modules/base.nix <<'NIX'
{ pkgs, ... }:

{
  time.timeZone = "Europe/Zagreb";

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    auto-optimise-store = true;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    nano
    htop
    tree
    jq
  ];

  system.autoUpgrade = {
    enable = false;
  };
}
NIX

echo "Writing modules/networking.nix..."

cat >modules/networking.nix <<'NIX'
{ ... }:

{
  networking = {
    useDHCP = false;

    # Let systemd-networkd and NetworkManager manage interfaces dynamically
    # until the final homelab networking design is known.
    networkmanager.enable = true;

    firewall = {
      enable = true;

      # Additional service ports will be opened by their own modules.
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };
}
NIX

echo "Writing modules/ssh.nix..."

cat >modules/ssh.nix <<'NIX'
{ ... }:

{
  services.openssh = {
    enable = true;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };
}
NIX

echo "Writing modules/users.nix..."

cat >modules/users.nix <<'NIX'
{ pkgs, ... }:

{
  users.users.vp = {
    isNormalUser = true;
    description = "Homelab administrator";

    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    packages = with pkgs; [
      git
    ];

    # Add your SSH public key later:
    #
    # openssh.authorizedKeys.keys = [
    #   "ssh-ed25519 AAAA..."
    # ];
  };

  security.sudo.wheelNeedsPassword = true;
}
NIX

echo "Writing modules/storage.nix..."

cat >modules/storage.nix <<'NIX'
{ ... }:

{
  # Disk partitions and file systems will be defined after inspecting
  # the actual homelab PC.
  #
  # The installer-generated hardware-configuration.nix will initially
  # contain the root file system and boot configuration.
}
NIX

echo "Writing modules/containers.nix..."

cat >modules/containers.nix <<'NIX'
{ ... }:

{
  virtualisation.docker = {
    enable = false;
  };

  virtualisation.podman = {
    enable = false;
  };

  # We will enable either Docker, Podman, or native NixOS services
  # after deciding how applications will be deployed.
}
NIX

echo "Writing modules/services/default.nix..."

cat >modules/services/default.nix <<'NIX'
{ ... }:

{
  # Homelab services will be imported here later.
  #
  # Example:
  #
  # imports = [
  #   ./jellyfin.nix
  #   ./nginx.nix
  # ];
}
NIX

echo
echo "Configuration files populated successfully."
echo
echo "Next commands:"
echo "  git add ."
echo "  nix flake lock"
echo "  nix flake check"

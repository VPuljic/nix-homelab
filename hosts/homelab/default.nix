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

    ../../modules/homelab
    ../../modules/services
  ];

  networking.hostName = "homelab";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  homelab = {
    enable = true;

    containers.enable = true;

    user = "vp";
    group = "homelab";

    timeZone = "Europe/Zagreb";

    # A domain will be configured later, if required.
    domain = null;

    paths = {
      state = "/srv/homelab";
      data = "/srv/data";
      backups = "/srv/backups";
    };
  };

  # Keep this value at the version used for the first installation.
  system.stateVersion = "26.05";
}

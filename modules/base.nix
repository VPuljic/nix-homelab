{ pkgs, ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Deduplicate identical files in the Nix store.
    auto-optimise-store = true;
  };

  # Remove unused Nix store paths while retaining recent generations.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  environment.systemPackages = with pkgs; [
    # Source control and network transfers
    git
    curl
    wget
    rsync

    # Editors and terminal utilities
    vim
    nano
    tmux

    # Process and storage inspection
    htop
    iotop
    ncdu
    tree
    lsof

    # Data and text processing
    jq
    ripgrep

    # Network diagnostics
    iperf3
    nmap

    # Hardware diagnostics
    pciutils
    usbutils
    lm_sensors
    smartmontools
  ];

  # Enable only after backups and rollback procedures have been tested.
  system.autoUpgrade = {
    enable = false;
  };
}

{ pkgs, ... }:

{
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

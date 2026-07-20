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

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

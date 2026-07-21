{ config, lib, ... }:

let
  cfg = config.homelab.secrets;
in
{
  options.homelab.secrets.enable =
    lib.mkEnableOption "encrypted secret deployment with agenix";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.openssh.enable;
        message = ''
          homelab.secrets requires OpenSSH so agenix can use the machine's
          SSH host keys for decryption.
        '';
      }
    ];

    # No encrypted files are declared yet. Agenix uses the NixOS OpenSSH host
    # private keys as its default decryption identities.
    age.secrets = { };
  };
}

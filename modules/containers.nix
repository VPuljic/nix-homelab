{ config, lib, ... }:

let
  cfg = config.homelab.containers;
in
{
  options.homelab.containers.enable =
    lib.mkEnableOption "the Podman-based OCI container platform";

  config = lib.mkIf cfg.enable {
    # Provide the shared /etc/containers configuration.
    virtualisation.containers.enable = true;

    # Podman is the selected container engine. Docker remains disabled.
    virtualisation.docker.enable = false;

    virtualisation.podman = {
      enable = true;

      # Allow software expecting the `docker` command to use Podman.
      dockerCompat = true;

      # Remove unused Podman resources once per week.
      autoPrune = {
        enable = true;
        dates = "weekly";
      };

      # Allow containers on the default Podman network to resolve one another.
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    # Declarative virtualisation.oci-containers definitions will use Podman.
    virtualisation.oci-containers.backend = "podman";
  };
}

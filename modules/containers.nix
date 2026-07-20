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

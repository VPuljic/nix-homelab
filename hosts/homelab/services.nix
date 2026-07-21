{ ... }:

{
  homelab.services = {
    # Enable the reusable service framework, but keep every application
    # disabled until the physical server, storage, and access model are ready.
    enable = true;

    homepage.enable = false;
  };
}

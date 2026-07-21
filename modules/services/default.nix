{ lib, ... }:

{
  imports = [
    ./homepage.nix
  ];

  options.homelab.services.enable =
    lib.mkEnableOption "the homelab application service framework";
}

{ config, lib, ... }:

let
  servicesCfg = config.homelab.services;
  cfg = servicesCfg.homepage;
in
{
  options.homelab.services.homepage.enable =
    lib.mkEnableOption "the Homepage homelab dashboard";

  config = lib.mkIf (servicesCfg.enable && cfg.enable) {
    services.homepage-dashboard.enable = true;
  };
}

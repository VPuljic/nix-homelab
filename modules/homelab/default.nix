{ config, lib, ... }:

let
  cfg = config.homelab;
in
{
  options.homelab = {
    enable = lib.mkEnableOption "the homelab platform";

    user = lib.mkOption {
      type = lib.types.str;
      default = "vp";
      description = "Primary user that owns homelab files.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "homelab";
      description = "Group used for access to homelab files.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Zagreb";
      description = "Time zone used by the homelab host and services.";
    };

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Base domain used for homelab services, when configured.";
    };

    paths = {
      state = lib.mkOption {
        type = lib.types.str;
        default = "/srv/homelab";
        description = "Persistent application configuration and state.";
      };

      data = lib.mkOption {
        type = lib.types.str;
        default = "/srv/data";
        description = "Persistent media and application data.";
      };

      backups = lib.mkOption {
        type = lib.types.str;
        default = "/srv/backups";
        description = "Local backup storage.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.timeZone;

    users.groups.${cfg.group} = { };

    users.users.${cfg.user}.extraGroups = [
      cfg.group
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.paths.state} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.paths.data} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.paths.backups} 0750 ${cfg.user} ${cfg.group} -"
    ];
  };
}

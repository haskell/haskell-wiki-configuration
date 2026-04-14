{ config, pkgs, lib, ... }:
with lib;
let cfg = config.services.hawiki;
in {
  options = {
    services.hawiki = {
      enable = mkEnableOption "Enable hawiki container";
      passFile = mkOption {
        type = types.str;
        description = ''
          CANNOT be in /tmp, because PrivateTmp=true in the unit that uses
          this file, deep in the guts of the mediawiki module.
        '';
      };
      url = mkOption {
        type = types.str;
        description = "The URL for the wiki";
        default = "wiki.haskell.org";
      };
      secure = mkOption {
        type = types.bool;
        default = true;
      };
      extensions = mkOption {
        type = types.attrsOf (types.nullOr types.path);
        default = {};
        description = ''
          Mediawiki extensions to override. These are merged (via //)
          on top of the defaults in the container config.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    users.users.hawiki = {
      isSystemUser = true;
      group = config.users.groups.hawiki.name;
    };
    users.groups.hawiki = {};

    systemd.tmpfiles.rules = [
      "d '/var/lib/hawiki' 0755 ${config.users.users.hawiki.name} ${config.users.groups.hawiki.name} - -"
    ];

    containers.hawiki = {
      autoStart = true;
      extraFlags = [ "--load-credential=hawiki-pass-file:${cfg.passFile}" ];
      bindMounts = {
        "hawiki" = {
          hostPath = "/var/lib/hawiki";
          mountPoint = "/var/lib/mediawiki";
          isReadOnly = false;
        };
      };

      config = {
        imports = [ ./hawiki-container-config.nix ];
        _module.args.hostConfig = config;
      };
    };
  };
}

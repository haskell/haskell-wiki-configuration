{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.hawiki;

  # Shared between wikimedia config and nginx config
  uploadPath = "/wikiupload";
  staticPath = "/wikistatic";

  # Static assets
  wikistatic = ../wikistatic;
in {
  options = {
    services.hawiki = {
      enable = mkEnableOption "Enable hawiki module";
      passFile = mkOption {
        type = types.str;
        description = ''
          File holding the initial admin password. Only read while installing
          a fresh wiki; an existing database is left alone.
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
          on top of the defaults in the module config.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services.mediawiki-init.serviceConfig.LoadCredential =
      [ "hawiki-pass-file:${cfg.passFile}" ];
    services.mediawiki = {
      enable = true;
      webserver = "none";
      url = "${if cfg.secure then "https" else "http"}://${cfg.url}";
      name = "HaskellWiki";
      passwordSender = "haskell-cafe@haskell.org";
      passwordFile = "/run/credentials/mediawiki-init.service/hawiki-pass-file";

      extraConfig = import ../mediawiki-config.nix { inherit uploadPath staticPath; };

      extensions = {
        Cite = null;
        CiteThisPage = null;
        CollapsibleVector = null;
        ConfirmEdit = null;
        Gadgets = null;
        ImageMap = null;
        InputBox = null;
        Math = null;
        Nuke = null;
        ParserFunctions = null;
        Poem = null;
        SimpleMathJax = null;
        SpamBlacklist = null;
        # Should be an alias, but only shows up as "GeSHi" still.
        SyntaxHighlight_GeSHi = null;
        SyntaxHighlightHaskellAlias = ../SyntaxHighlightHaskellAlias;
        TemplateStyles = null;
        TitleBlacklist = null;
        WikiEditor = null;
      } // cfg.extensions;

      database = {
        type = "mysql";
        createLocally = true;
      };
    };

    services.memcached = {
      enable = true;
    };

    systemd.services.nginx.serviceConfig = {
      SupplementaryGroups = [ config.users.groups.mediawiki.name ];
    };

    services.nginx = {
      enable = true;
      # inspired by https://www.mediawiki.org/wiki/Manual:Short_URL/Nginx
      virtualHosts.${config.services.mediawiki.nginx.hostName} = {
        root = "${config.services.mediawiki.finalPackage}/share/mediawiki";
        listen = [
          {
            addr = "127.0.0.1";
            port = 8081;
          }
        ];
        locations = let
          withTrailingSlash = str: if lib.hasSuffix "/" str then str else "${str}/";
          in {
          "~ ^/(index|load|api|thumb|opensearch_desc|rest|img_auth)\\.php$".extraConfig = ''
            include ${config.services.nginx.package}/conf/fastcgi.conf;
            fastcgi_index index.php;
            fastcgi_pass unix:${config.services.phpfpm.pools.mediawiki.socket};
            '';
          "${uploadPath}/".alias = withTrailingSlash config.services.mediawiki.uploadsDir;
          # Deny access to deleted images folder
          "${uploadPath}/deleted".extraConfig = ''
            deny all;
            '';
          # MediaWiki assets (usually images)
          "~ ^/resources/(assets|lib|src)".extraConfig = ''
            rewrite ^/w(/.*) $1 break;
            add_header Cache-Control "public";
            expires 7d;
            '';
            # Assets, scripts and styles from skins and extensions
            "~ ^/(skins|extensions)/.+\\.(css|js|gif|jpg|jpeg|png|svg|wasm|ttf|woff|woff2)$".extraConfig = ''
              rewrite ^(/.*) $1 break;
              add_header Cache-Control "public";
              expires 7d;
              '';

            # Handling for Mediawiki REST API, see [[mw:API:REST_API]]
          "/rest.php/".tryFiles = "$uri $uri/ /rest.php?$query_string";

            # Custom modification used on Haskell wiki
            "^~ ${staticPath}/".alias = withTrailingSlash wikistatic;

            # Handling for the article path (pretty URLs)
            "/".extraConfig = ''
              rewrite ^/(?<pagename>.*)$ /index.php?title=$1;
              '';
        };
      };
    };
  };
}

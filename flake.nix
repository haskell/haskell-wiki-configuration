{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: {
    nixosModules.hawiki = { config, pkgs, lib, ... }:
      with lib;
      let cfg = config.services.hawiki;
      in {
        options = {
          services.hawiki = {
            enable = mkEnableOption "Enable hawiki container";
            passFile = mkOption {
              type = types.path;
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

          containers.hawiki = let passPath = config.sops.secrets.hawiki-pass.path; in {
            autoStart = true;

            bindMounts = {
              "${cfg.passFile}" = {
                isReadOnly = true;
              };
              "hawiki" = {
                hostPath = "/var/lib/hawiki";
                mountPoint = "/var/lib/mediawiki";
                isReadOnly = false;
              };
            };

            config = { config, pkgs, lib, ... }:
            let
              # Shared between wikimedia config and nginx config
              uploadPath = "/wikiupload";
            in {
              system.stateVersion = "24.05";

              networking.useDHCP = false;
              networking = {
                firewall = {
                  enable = true;
                  allowedTCPPorts = [ 8081 ];
                };
                useHostResolvConf = lib.mkForce false;
              };

              services.mediawiki = {
                enable = true;
                webserver = "none";
                url = "${if cfg.secure then "https" else "http"}://${cfg.url}";
                name = "HaskellWiki";
                passwordSender = "haskell-cafe@haskell.org";
                passwordFile = cfg.passFile;

                nginx.hostName = cfg.url;

                extraConfig =
                  ''
                  $wgEmergencyContact = "haskell-cafe@haskell.org";

                  $wgMainCacheType = CACHE_MEMCACHED;
                  $wgMemCachedServers = array( "127.0.0.1:11211" );
                  $wgSessionsInObjectCache = true;
                  $wgSessionCacheType = CACHE_MEMCACHED;
                  $wgSessionsInMemcached = true;
                  $wgEnableSidebarCache = true;

                  $wgDisableCounters = true;

                  $wgEnableCreativeCommonsRdf = true;
                  $wgRightsPage = "HaskellWiki:Copyrights";
                  $wgRightsUrl  = "https://wiki.haskell.org/HaskellWiki:Copyrights";
                  $wgRightsText = "simple permissive license";

                  $wgMathValidModes = ['source', 'native', 'mathjax' ];
                  $wgDefaultUserOptions['math'] = 'native';

                  unset( $wgFooterIcons['poweredby'] );

                  # Edit and user-creation restrictions

                  ## Don't allow anonymous users to edit
                  $wgGroupPermissions['*']['edit'] = false;

                  ## Don't even let them sign up
                  $wgGroupPermissions['*']['createaccount'] = false;

                  ## Somewhat redundantly, require email confirmation to edit
                  $wgEmailConfirmToEdit = true;

                  ## The createaccount group, for users who can always create accounts
                  $wgAvailableRights[] = 'createaccount';
                  $wgGroupPermissions['createaccount']['createaccount'] = true;


                  # This is used to render URLs to uploaded files.
                  $wgUploadPath = '${uploadPath}';

                  # Let users opt in to various notifications
                  $wgEnotifUserTalk = true;
                  $wgEnotifWatchlist = true;

                  # This is the default, but timezones are scary so let's be
                  # specific.
                  $wgLocaltimezone = 'UTC';

                  # Duplicate earlier legacy settings.
                  $wgNamespacesWithSubpages[NS_MAIN] = true;
                  $wgNamespacesWithSubpages[NS_CATEGORY] = true;

                  # Disable cache-busting that Nix defeats anyway
                  $wgInvalidateCacheOnLocalSettingsChange = false;
                  '';

                extensions = {
                  Cite = null;
                  SyntaxHighlight_GeSHi = null;
                  Math = null;
                  Interwiki = null;
                  WikiEditor = null;
                  CiteThisPage = null;
                  ConfirmEdit = null;
                  Gadgets = null;
                  ImageMap = null;
                  InputBox = null;
                  Nuke = null;
                  ParserFunctions = null;
                  Poem = null;

                  #TemplateStyles = pkgs.fetchgit
                  #  { url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles";
                  #    rev = "522187051d9ddfd584934620b393a4966dd6a6a6";
                  #    sha256 = "0zzbhf5787ffza4n0kz5a5ra7vkmk51w8lv0dr2h1rgg4jmnd5mq";
                  #  };
                  SpamBlacklist = null;
                  TitleBlacklist = null;
                  SimpleMathJax = builtins.fetchGit
                    { url = "https://github.com/jmnote/SimpleMathJax.git";
                      rev = "fab35e6ac66e1f5abd3c91a57719f8180dd346ef";
                    };
                  CollapsibleVector = pkgs.fetchgit
                    { url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/CollapsibleVector";
                      rev = "3fddfb23f86061bbfafda6554b1d7c5f11edfcac";
                      sha256 = "0fl80l3xi4fl98msmbwdi8vzynaaa9r6lp37hpb7faxhpkzb9wxh";
                    };
                  SyntaxHighlightHaskellAlias = ./SyntaxHighlightHaskellAlias;
                };

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

                     # Handling for the article path (pretty URLs)
                     "/".extraConfig = ''
                       rewrite ^/(?<pagename>.*)$ /index.php?title=$1;
                       '';
                  };
                };
              };
            };
          };
        };
      };
  };
}

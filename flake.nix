{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: {
    nixosModules.hawiki = { config, pkgs, lib, ... }:
      let let cfg = config.services.hawiki;
      in {
        options = {
          services.hawiki = {
            enable = mkEnableOption "Enable hawiki container";
            passFile = mkOption {
              type = types.path;
              description = "";
            };
            url = mkOption {
              type = types.string;
              description = "The URL for the wiki";
              default = "wiki.haskell.org";
            };
          };
        };
        
        config = lib.mkIf cfg.enable {

          systemd.tmpfiles.rules = [
            "d '/var/lib/hawiki' 0755 ${config.users.users.hawiki.name} ${config.users.groups.hawiki.name} - -"
          ];
          
          containers.hawiki = let passPath = config.sops.secrets.hawiki-pass.path; in {
            system.stateVersion = "24.05";
            boot.isContainer = true;   
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
            
            networking.useDHCP = false;
            networking = {
              firewall = {
                enable = true;
                allowedTCPPorts = [ 80 ];
              };
              useHostResolvConf = lib.mkForce false;
            };
            
            services.mediawiki = {
              enable = true;
              webserver = "nginx";
              url = cfg.url;
              name = "HaskellWiki";
              passwordSender = "haskell-cafe@haskell.org";
              passwordFile = cfg.passFile;
              
              httpd.virtualHost = {
                hostName = "wiki.haskell.org";
              };
              
              extensions = {
                Cite = null;
                SyntaxHighlight_GeSHi = null;
                Math = null;
                #Wikidiff2 = null;                                                                                                                                                                  
                Interwiki = null;
                WikiEditor = null;
                CiteThisPage = null;
                ConfirmEdit = null;
                Gadgets = null;
                ImageMap = null;
                InputBox = null;
                # LocalisationUpdate = null; # Depricated                                                                                                                                           
                Nuke = null;
                ParserFunctions = null;
                Poem = null;
                # Renameuser = null; # Part of mediawiki proper since 1.40                                                                                                                          
                SpamBlacklist = null;
                TitleBlacklist = null;
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
          };
        };
      };
  };
}

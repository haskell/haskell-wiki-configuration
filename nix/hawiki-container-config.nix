{ hostConfig, config, pkgs, lib, ... }:

let
  cfg = hostConfig.services.hawiki;

  # Shared between wikimedia config and nginx config
  uploadPath = "/wikiupload";
  staticPath = "/wikistatic";

  # ??
  wikistatic = ../wikistatic;
in {

system.stateVersion = "24.05";

# Not enough memory on the system for this.
boot.tmp.useTmpfs = false;

networking.useDHCP = false;
networking = {
  firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 ];
  };
  useHostResolvConf = lib.mkForce false;
};
systemd.services.mediawiki = {
  serviceConfig.LoadCredential = [ "hawiki-pass-file:hawiki-pass-file" ];
  serviceConfig.Environment = [ "HAWIKI_PASS_FILE=%d/hawiki-pass-file" ];
};
services.mediawiki = {
  enable = true;
  webserver = "none";
  url = "${if cfg.secure then "https" else "http"}://${cfg.url}";
  name = "HaskellWiki";
  passwordSender = "haskell-cafe@haskell.org";
  passwordFile = "/var/lib/mediawiki/hawiki-pass";

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

    # Static assets
    $wgLogos = [
      # Not enabled cause it is not square and looks like garbage
      # after getting squashed.
      # 'icon' => "${staticPath}/haskellwiki_logo.png",
      '1x' => "${staticPath}/haskellwiki_logo.png",
      '2x' => "${staticPath}/haskellwiki_logo.png",
    ];
    $wgFavicon          = "${staticPath}/favicon.ico";
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

    # FIXME TemplateStyles disabled because it's causing internal errors. Or,
    # something is, and I'm guessing it's the new/changed version of
    # TemplateStyles. Let's find out!
    #
    ## TODO: Remove this manual installation of TemplateStyles once MediaWiki is upgraded to 1.44 or later,
    ## since the TemplateStyles extension will be bundled by default starting from that version.

    #TemplateStyles = builtins.fetchGit {
    #  url = "https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles.git";
    #  # Tag REL1_38, the last one I can find in the repo.
    #  rev = "e0aa1fac05bcf580b539c1707d889dcfb4701cb0";
    #};
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
    SyntaxHighlightHaskellAlias = ../SyntaxHighlightHaskellAlias;
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

        # Custom modification used on Haskell wiki
        "^~ ${staticPath}/".alias = withTrailingSlash wikistatic;

        # Handling for the article path (pretty URLs)
        "/".extraConfig = ''
          rewrite ^/(?<pagename>.*)$ /index.php?title=$1;
          '';
    };
  };
};
}

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
  nameservers = [ "8.8.8.8" "8.8.4.4" "208.67.220.220" "208.67.222.222" ];
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
  passwordFile = "/var/lib/mediawiki/initial-password";

  nginx.hostName = cfg.url;

  extraConfig =
    ''
    $wgEmergencyContact = "haskell-cafe@haskell.org";

    # Outbound mail relayed via mail.haskell.org
    $wgSMTP = [
      'host'      => 'mail.haskell.org',
      'IDHost'    => 'wiki.haskell.org',
      'localhost' => 'wiki.haskell.org',
      'port'      => 25,
      'auth'      => false,
      'timeout'   => 5,
    ];

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

    # Responsive design: sets viewport to width=device-width instead of width=1120
    $wgVectorResponsive = true;

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
    CiteThisPage = null;
    CollapsibleVector = null;
    ConfirmEdit = null;
    Gadgets = null;
    ImageMap = null;
    InputBox = null;
    Interwiki = null;
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
}

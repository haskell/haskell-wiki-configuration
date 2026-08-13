# Settings appended to MediaWiki's LocalSettings.php.
{ uploadPath, staticPath }:

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
''

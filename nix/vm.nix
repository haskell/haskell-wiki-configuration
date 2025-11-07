{ pkgs, config, modulesPath, ...}:
let
  stateDir = "/var/lib/hawiki";
in {
  imports = [
    ./module.nix
    "${modulesPath}/virtualisation/qemu-vm.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];
  system.stateVersion = "24.11";
  networking.hostName = "hawiki-vm";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 ];
  };

  boot.loader.grub.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  services.getty.autologinUser = "root";

  services.qemuGuest.enable = true;

  virtualisation = {
    memorySize = 2048; # MB
    diskSize = 8000; # MB
    cores = 1;
    graphics = false;
    sharedDirectories = {
      brokerConfig = {
        source = "$HAWIKI_STATE";
        target = stateDir;
      };
    };
    forwardPorts = [
      { from = "host"; host.port = 18888; guest.port = 8081; }
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      default = true;
      locations."/" = {
        proxyPass = "http://localhost:8081";
      };
    };
  };

  services.hawiki = {
    enable = true;
      passFile = "${stateDir}/hawiki-pass";
      url = "localhost:18888";
      secure = false;
  };
}

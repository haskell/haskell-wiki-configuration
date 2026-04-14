{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  inputs.mediawikiPlugin_CollapsibleVector = {
    url = "git+https://gerrit.wikimedia.org/r/mediawiki/extensions/CollapsibleVector";
    flake = false;
  };
  inputs.mediawikiPlugin_SimpleMathJax = {
    url = "github:jmnote/SimpleMathJax";
    flake = false;
  };

  outputs = inputs@{ self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    hawikiExtensions = {
      CollapsibleVector = inputs.mediawikiPlugin_CollapsibleVector;
      SimpleMathJax = inputs.mediawikiPlugin_SimpleMathJax;
    };
  in {
    nixosModules.hawiki = { ... }: {
      imports = [ ./nix/module.nix ];
      services.hawiki.extensions = hawikiExtensions;
    };
    nixosConfigurations.hawiki-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ self.nixosModules.hawiki ./nix/vm.nix ];
    };
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        shellHook = ''
          export HAWIKI_STATE=$(pwd)/hawiki-state/
        '';
        packages = [ pkgs.just ];
      };
    });
  };
}

{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    nixosModules.hawiki = import ./nix/module.nix;
    nixosConfigurations.hawiki-vm = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./nix/vm.nix ];
    };
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        shellHook = ''
          export HAWIKI_CONFIG=$(pwd)/hawiki-config/
        '';
      };
    });
  };
}

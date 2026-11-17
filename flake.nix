{
  description = "Spanish DNIe and AutoFirma on NixOS in one module";

  # Consumers must not make these inputs follow their nixpkgs: the Maven
  # hashes in fixed-output-derivations.lock only match the Maven of this pin.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    autofirma-nix = {
      url = "github:nix-community/autofirma-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      autofirma-nix,
    }:
    let
      # The Maven hashes are only computed and tested on x86_64-linux.
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      example = nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.default
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            boot.loader.grub.enable = false;
            fileSystems."/".fsType = "tmpfs";
            system.stateVersion = "26.05";
            programs.firefox.enable = true;
            programs.dnie.enable = true;
          }
        ];
      };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          autofirma-set = autofirma-nix.lib.mkAutofirma pkgs {
            maven-dependencies-hash = builtins.fromJSON (builtins.readFile ./fixed-output-derivations.lock);
            maven-dependency-versions = builtins.fromJSON (builtins.readFile ./maven-dependency-versions.lock);
          };
        in
        {
          inherit (autofirma-set) autofirma;
          default = autofirma-set.autofirma;
          # Rebuilds the Maven fixed-output derivations and rewrites both lock files.
          update-hashes = pkgs.callPackage "${autofirma-nix}/nix/tools/update-fixed-output-derivations" { };
        }
      );

      nixosModules.default = import ./module.nix { inherit self autofirma-nix nixpkgs; };

      checks.x86_64-linux.autofirma = example.config.programs.autofirma.finalPackage;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}

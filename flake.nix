{
  description = "Spanish DNIe and AutoFirma on NixOS in one module";

  # Do not make autofirma-nix follow your nixpkgs. Its Maven hashes only match
  # the Maven of its own pinned nixpkgs.
  inputs.autofirma-nix.url = "github:nix-community/autofirma-nix";

  outputs =
    { self, autofirma-nix }:
    let
      inherit (autofirma-nix.inputs) nixpkgs;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      example = nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.default
          {
            nixpkgs.hostPlatform = system;
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
      nixosModules.default = import ./module.nix autofirma-nix;

      checks.${system}.autofirma = example.config.programs.autofirma.finalPackage;

      formatter.${system} = pkgs.nixfmt-tree;
    };
}

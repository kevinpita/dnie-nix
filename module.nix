autofirma-nix:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.dnie;
  inherit (pkgs.stdenv.hostPlatform) system;
  upstreamPkgs = autofirma-nix.inputs.nixpkgs.legacyPackages.${system};
in
{
  imports = [ autofirma-nix.nixosModules.autofirma ];

  options.programs.dnie.enable = lib.mkEnableOption "Spanish DNIe support with AutoFirma";

  config = lib.mkIf cfg.enable {
    services.pcscd.enable = true;

    environment.systemPackages = [
      pkgs.opensc
      pkgs.pcsc-tools
    ];

    programs.autofirma = {
      enable = true;
      firefoxIntegration.enable = lib.mkDefault true;
      # AutoFirma runs in an FHS env without libpcsclite, so it cannot reach pcscd.
      # Use the pcsclite of this system so the client matches the daemon.
      package = lib.mkDefault (
        autofirma-nix.packages.${system}.autofirma.override {
          buildFHSEnv =
            args:
            upstreamPkgs.buildFHSEnv (
              args // { targetPkgs = fhsPkgs: args.targetPkgs fhsPkgs ++ [ pkgs.pcsclite.lib ]; }
            );
        }
      );
    };

    programs.firefox.policies.SecurityDevices."OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
  };
}

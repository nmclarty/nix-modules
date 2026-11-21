{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.custom.disks.root;
  mirrored = builtins.length cfg.devices == 2;
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            configurationLimit = 5;
            enable = !cfg.secureBoot;
          };
        };
        lanzaboote.extraEfiSysMountPoints = mkIf mirrored [ "/boot2" ];
        # To silence eval warning "`boot.zfs.forceImportRoot` is using the default value of `true"...
        zfs.forceImportRoot = false;
      };
    }

    (mkIf cfg.secureBoot {
      # sbctl to manage keys and for debugging
      environment.systemPackages = [ pkgs.sbctl ];
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };
    })
  ]);
}

{ config, lib, ... }:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.custom.disks.root;
  mirrored = builtins.length cfg.devices == 2;
in
{
  config = mkIf (cfg.enable && cfg.encrypt) (mkMerge [
    {
      boot = {
        # the import only polls for the pool briefly, so it can time out while a passphrase is typed
        initrd.systemd.services.zfs-import-zroot = {
          wants = [ "cryptsetup.target" ];
          after = [ "cryptsetup.target" ];
        };
        lanzaboote = {
          # pcrlock refuses policies with more than 8 variants of PCR 4 (2 boot loaders × 4 generations)
          configurationLimit = 4;
          measuredBoot = {
            enable = true;
            # 1-3 are skipped since they change with firmware settings and add-in cards
            pcrs = [
              0
              4
              7
            ];
          };
        };
      };
    }

    # pcrlock only writes the policy credential to /boot, but the stub reads it from whichever ESP booted
    (mkIf mirrored {
      systemd = {
        paths.pcrlock-credential-sync = {
          wantedBy = [ "paths.target" ];
          pathConfig.PathChanged = "/boot/loader/credentials";
        };

        services.pcrlock-credential-sync = {
          # the boot-time policy update runs before the path unit is watching
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-pcrlock-make-policy.service" ];
          # with a dead primary, the empty /boot would wipe the copy on /boot2
          unitConfig.RequiresMountsFor = [
            "/boot"
            "/boot2"
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /boot2/loader
            rm -rf /boot2/loader/credentials
            cp -r /boot/loader/credentials /boot2/loader/credentials
          '';
        };
      };
    })
  ]);
}

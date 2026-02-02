{ config, lib, ... }:
let
  cfg = config.custom.disks.cold;
  listLength = builtins.length cfg.disks;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = listLength == 2;
        message = "Cold disk type 'zfs' requires 2 disks.";
      }
    ];
    boot.zfs.extraPools = [ "cold" ];
    disko.devices = {
      disk = builtins.listToAttrs (
        map
          (disk: {
            name = disk;
            value = {
              type = "disk";
              device = disk;
              content = {
                type = "gpt";
                partitions.zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "cold";
                  };
                };
              };
            };
          })
          cfg.disks
      );

      zpool.cold = {
        type = "zpool";
        mode = "mirror";
        options.ashift = "12";
        rootFsOptions = {
          compression = "lz4";
          xattr = "sa";
          mountpoint = "none";
          # encryption
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///run/secrets/zfs/cold";
        };
        datasets = {
          backup = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          garage = {
            type = "zfs_fs";
            options.mountpoint = "/cold/garage";
          };
          shares = {
            type = "zfs_fs";
            options.mountpoint = "/cold/shares";
          };
          vault = {
            type = "zfs_fs";
            options.mountpoint = "/cold/vault";
          };
        };
      };
    };
  };
}

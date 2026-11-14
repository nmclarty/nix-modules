{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.custom.disks.cold;
in
{
  options.custom.disks.cold = {
    enable = mkEnableOption "If cold zfs pool config should be enabled.";
    disks = mkOption {
      type = with types; listOf str;
      description = "The list of disk devices to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.length cfg.disks == 2;
        message = "Cold disk type 'zfs' requires 2 disks.";
      }
    ];
    sops.secrets."zfs/cold_key".sopsFile = config.custom.base.secrets.system;
    boot.zfs.extraPools = [ "cold" ];
    disko.devices = {
      disk = builtins.listToAttrs (
        map (disk: {
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
        }) cfg.disks
      );

      zpool.cold = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autoexpand = "on";
        };
        rootFsOptions = {
          compression = "lz4";
          xattr = "sa";
          dnodesize = "auto";
          acltype = "posixacl";
          mountpoint = "none";
          encryption = "on";
          keyformat = "hex";
          keylocation = "file://${config.sops.secrets."zfs/cold_key".path}";
        };
        datasets = {
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

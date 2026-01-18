{ config, lib, ... }:
let
  cfg = config.custom.disks.root;
  listLength = builtins.length cfg.disks;
  firstDisk = builtins.elemAt cfg.disks 0;
  secondDisk = if builtins.length cfg.disks == 2 then builtins.elemAt cfg.disks 1 else "";
in
{
  config = lib.mkIf (cfg.enable && cfg.type == "zfs") {
    assertions = [
      {
        assertion = builtins.elem listLength [ 1 2 ];
        message = "Root disk type 'zfs' requires 1 or 2 disks.";
      }
    ];
    disko.devices = {
      disk = {
        ${firstDisk} = {
          type = "disk";
          device = firstDisk;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      } // lib.optionalAttrs (listLength == 2) {
        ${secondDisk} = {
          type = "disk";
          device = secondDisk;
          content = {
            type = "gpt";
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };

      zpool.zroot = {
        type = "zpool";
        mode = lib.mkIf (listLength == 2) "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "lz4";
          xattr = "sa";
          mountpoint = "none";
        };
        datasets = {
          nixos = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          srv = {
            type = "zfs_fs";
            mountpoint = "/srv";
          };
          # these datasets should only contain cached/generated data
          # so they don't need to be backed up by zfs replication
          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."syncoid:sync" = "false";
          };
          "nixos/cache" = {
            type = "zfs_fs";
            mountpoint = "/var/cache";
            options."syncoid:sync" = "false";
          };
          "nixos/containers" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/containers";
            options."syncoid:sync" = "false";
          };
        };
      };
    };
  };
}

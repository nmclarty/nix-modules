{ config, lib, ... }:
let
  cfg = config.custom.disks.root;
  listLength = builtins.length cfg.disks;
  secondDisk = if builtins.length cfg.disks == 2 then builtins.elemAt cfg.disks 1 else "";
  # added to every disk so mirrored zfs partitions stay the same size
  swapPartition = lib.optionalAttrs (cfg.swapSize != null) {
    swap = {
      size = cfg.swapSize;
      content = {
        type = "swap";
        randomEncryption = true;
      };
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.elem listLength [
          1
          2
        ];
        message = "Root disk requires 1 or 2 disks.";
      }
    ];

    # To silence eval warning "`boot.zfs.forceImportRoot` is using the default value of `true"...
    boot.zfs.forceImportRoot = false;
    services.zfs.autoScrub.enable = true;

    disko.devices = {
      disk = {
        primary = {
          type = "disk";
          device = builtins.elemAt cfg.disks 0;
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
            }
            // swapPartition
            // {
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
      }
      // lib.optionalAttrs (listLength == 2) {
        ${secondDisk} = {
          type = "disk";
          device = secondDisk;
          content = {
            type = "gpt";
            partitions = swapPartition // {
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
        mode = lib.mkIf (listLength == 2 && cfg.mode == "mirror") "mirror";
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
          # no fileSystems entry, since it would race zfs-mount at boot
          srv = {
            type = "zfs_fs";
            options.mountpoint = "/srv";
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
            options = {
              mountpoint = "/var/cache";
              "syncoid:sync" = "false";
            };
          };
          "nixos/containers" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/var/lib/containers";
              "syncoid:sync" = "false";
            };
          };
        };
      };
    };
  };
}

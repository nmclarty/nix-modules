{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    nameValuePair
    optional
    optionalAttrs
    imap0
    ;
  cfg = config.custom.disks.root;
  mirrored = builtins.length cfg.devices == 2;
  # added to every disk so mirrored zfs partitions stay the same size
  swapPartition = optionalAttrs (cfg.swapSize != null) {
    swap = {
      size = cfg.swapSize;
      content = {
        type = "swap";
        randomEncryption = true;
      };
    };
  };
  zfsContent =
    name:
    let
      pool = {
        type = "zfs";
        pool = "zroot";
      };
    in
    if cfg.encrypt then
      {
        type = "luks";
        name = "crypt-${name}";
        settings = {
          allowDiscards = true;
          crypttabExtraOpts = [ "tpm2-device=auto" ];
        };
        content = pool;
      }
    else
      pool;

  mkDisk =
    index: device:
    let
      primary = index == 0;
      name = if primary then "primary" else "secondary";
    in
    nameValuePair name {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = if primary then "/boot" else "/boot2";
              # either disk may be the one that died
              mountOptions = [ "umask=0077" ] ++ optional mirrored "nofail";
            };
          };
        }
        // swapPartition
        // {
          zfs = {
            size = "100%";
            content = zfsContent name;
          };
        };
      };
    };
in
{
  config = mkIf cfg.enable {
    services.zfs.autoScrub.enable = true;

    disko.devices = {
      disk = builtins.listToAttrs (imap0 mkDisk cfg.devices);

      zpool.zroot = {
        type = "zpool";
        mode = mkIf mirrored "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "lz4";
          xattr = "sa";
          dnodesize = "auto";
          acltype = "posixacl";
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

          "nixos/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };

          "nixos/cache" = {
            type = "zfs_fs";
            options.mountpoint = "/var/cache";
          };

          "nixos/containers" = {
            type = "zfs_fs";
            options.mountpoint = "/var/lib/containers";
          };
        };
      };
    };
  };
}

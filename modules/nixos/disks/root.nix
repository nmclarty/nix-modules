{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;
  cfg = config.custom.disks.root;
  mirrored = builtins.length cfg.disks == 2;
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
    lib.nameValuePair name {
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
              mountOptions = [ "umask=0077" ] ++ lib.optional mirrored "nofail";
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
  options.custom.disks.root = {
    enable = mkEnableOption "If root disko config should be enabled.";
    disks = mkOption {
      type = with types; listOf str;
      description = "The list of disk devices to use, mirrored when there are two.";
    };
    swapSize = mkOption {
      type = with types; nullOr str;
      default = "4G";
      description = "Size of the swap partition added to each root disk, or null for none. When set, zswap is used instead of zram.";
    };
    encrypt = mkEnableOption "If root zfs partitions should be LUKS encrypted and unlocked by the TPM via measured boot.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = builtins.elem (builtins.length cfg.disks) [
            1
            2
          ];
          message = "Root disk requires 1 or 2 disks.";
        }
        {
          assertion = mirrored -> config.custom.base.secure-boot.enable;
          message = "Mirrored root disks require secure boot, since only lanzaboote installs to both ESPs.";
        }
      ];

      boot = {
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot = {
            configurationLimit = 5;
            enable = true;
          };
        };
        lanzaboote.extraEfiSysMountPoints = mkIf mirrored [ "/boot2" ];
        # To silence eval warning "`boot.zfs.forceImportRoot` is using the default value of `true"...
        zfs.forceImportRoot = false;
      };
      services.zfs.autoScrub.enable = true;

      disko.devices = {
        disk = builtins.listToAttrs (lib.imap0 mkDisk cfg.disks);
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
    }
    (mkIf cfg.encrypt {
      assertions = [
        {
          assertion = config.custom.base.secure-boot.enable;
          message = "Root disk encryption requires secure boot for measured boot.";
        }
      ];
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
    })
    # pcrlock only writes the policy credential to /boot, but the stub reads it from whichever ESP booted
    (mkIf (cfg.encrypt && mirrored) {
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
    # migrate hosts to zswap incrementally, when they are repartitioned
    (mkIf (cfg.swapSize != null) {
      zramSwap.enable = false;
      boot.kernelParams = [
        "zswap.enabled=1"
        "zswap.compressor=zstd"
        "zswap.max_pool_percent=25"
        "zswap.shrinker_enabled=1"
      ];
    })
  ]);
}

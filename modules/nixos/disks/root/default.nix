{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.custom.disks.root;
  mirrored = builtins.length cfg.devices == 2;
in
{
  imports = [
    ./layout.nix
    ./boot.nix
    ./encrypt.nix
    ./swap.nix
  ];

  options.custom.disks.root = {
    enable = mkEnableOption "If root disko config should be enabled.";
    devices = mkOption {
      type = with types; listOf str;
      description = "The disk devices to use, mirrored when there are two.";
    };
    swapSize = mkOption {
      type = with types; nullOr str;
      default = "4G";
      description = "Size of the swap partition added to each root disk, or null for none. When set, zswap is used instead of zram.";
    };
    secureBoot = mkEnableOption "If lanzaboote should replace systemd-boot, with keys generated and enrolled automatically.";
    encrypt = mkEnableOption "If root zfs partitions should be LUKS encrypted and unlocked by the TPM via measured boot.";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.devices != [ ] && builtins.length cfg.devices <= 2;
        message = "Root disk requires 1 or 2 devices.";
      }
      {
        assertion = mirrored -> cfg.secureBoot;
        message = "Mirrored root disks require secure boot, since only lanzaboote installs to both ESPs.";
      }
      {
        assertion = cfg.encrypt -> cfg.secureBoot;
        message = "Root disk encryption requires secure boot for measured boot.";
      }
    ];
  };
}

{ inputs, ... }:
{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    mkMerge
    ;
  cfg = config.custom.disks;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./root.nix
    ./cold.nix
  ];
  options.custom.disks = {
    root = {
      enable = mkEnableOption "If root disko config should be enabled.";
      mode = mkOption {
        type = types.enum [
          "mirror"
          "stripe"
        ];
        default = "mirror";
        description = "Which mode to use for aggregating data between disks.";
      };
      disks = mkOption {
        type = with types; listOf str;
        description = "The list of disk devices to use.";
      };
      swapSize = mkOption {
        type = with types; nullOr str;
        default = "4G";
        description = "Size of the swap partition added to each root disk, or null for none. When set, zswap is used instead of zram.";
      };
    };
    cold = {
      enable = mkEnableOption "If cold zfs pool config should be enabled.";
      disks = mkOption {
        type = with types; listOf str;
        description = "The list of disk devices to use.";
      };
    };
  };
  config = mkMerge [
    (mkIf cfg.root.enable {
      boot.loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          configurationLimit = 5;
          enable = true;
        };
      };
    })
    # migrate hosts to zswap incrementally, when they are repartitioned
    (mkIf (cfg.root.enable && cfg.root.swapSize != null) {
      zramSwap.enable = false;
      boot.kernelParams = [
        "zswap.enabled=1"
        "zswap.compressor=zstd"
        "zswap.max_pool_percent=25"
        "zswap.shrinker_enabled=1"
      ];
    })
  ];
}

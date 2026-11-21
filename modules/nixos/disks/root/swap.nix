{ config, lib, ... }:
let
  cfg = config.custom.disks.root;
in
{
  # migrate hosts to zswap incrementally, when they are repartitioned
  config = lib.mkIf (cfg.enable && cfg.swapSize != null) {
    zramSwap.enable = false;
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=25"
      "zswap.shrinker_enabled=1"
    ];
  };
}

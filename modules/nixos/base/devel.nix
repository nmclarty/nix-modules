{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.base.devel;
in
{
  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;
  };
}

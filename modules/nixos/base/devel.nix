{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf lists;
  cfg = config.custom.base.devel;
in
{
  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;
  };
}

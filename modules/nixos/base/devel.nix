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
    boot.binfmt.emulatedSystems = lists.filter (s: s != pkgs.stdenv.hostPlatform.system) [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}

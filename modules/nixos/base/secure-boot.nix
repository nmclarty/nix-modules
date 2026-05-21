{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.custom.base.secure-boot;
in
{
  config = mkIf cfg.enable {
    # sbctl to manage keys and for debugging
    environment.systemPackages = with pkgs; [ sbctl ];
    boot = {
      # lanzaboote replaces systemd-boot
      loader.systemd-boot.enable = lib.mkForce false;
      lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        # automatic provisioning
        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };
    };
  };
}

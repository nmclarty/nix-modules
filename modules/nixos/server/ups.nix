{ config, lib, flake, ... }:
let
  inherit (lib) mkMerge mkIf;
  cfg = config.custom.server.ups;
  # find the hostname of the first computer that is a ups server
  upsServer = lib.findFirst
    (name: with flake.nixosConfigurations.${name}.config; custom ? server && custom.server.ups.type == "server")
    (throw "No UPS server found")
    (builtins.attrNames flake.nixosConfigurations);
in
{
  config = mkMerge [
    (mkIf (cfg.enable && cfg.type == "client") {
      sops.secrets."nut/monitor" = { };

      power.ups = {
        enable = true;
        mode = "netclient";
        users.monitor = {
          passwordFile = config.sops.secrets."nut/monitor".path;
          upsmon = "secondary";
        };
        upsmon.monitor.primary = {
          passwordFile = config.sops.secrets."nut/monitor".path;
          system = "primary@${upsServer}";
          type = "secondary";
          user = "monitor";
        };
      };
    })

    (mkIf (cfg.enable && cfg.type == "server") {
      sops.secrets."nut/admin" = { };

      # for some reason, nut seems to spam this (seemingly) benign error
      systemd.services.upsdrv.serviceConfig.LogFilterPatterns = "~nut_libusb_get_(report|string): Input/Output Error";
      power.ups = {
        enable = true;
        mode = "netserver";
        upsd.listen = [{ address = "0.0.0.0"; }];
        ups.primary = {
          driver = "usbhid-ups";
          port = "auto";
          directives = [ "pollfreq = 5" "productid = 0601" "pollonly" ];
        };
        users.admin = {
          passwordFile = config.sops.secrets."nut/admin".path;
          actions = [ "SET" "FSD" ];
          instcmds = [ "ALL" ];
          upsmon = "primary";
        };
        upsmon.monitor.primary = {
          passwordFile = config.sops.secrets."nut/admin".path;
          system = "primary@127.0.0.1";
          type = "primary";
          user = "admin";
        };
      };
    })
  ];
}

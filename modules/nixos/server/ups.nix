{ lib, config, ... }:
let
  inherit (lib) mkMerge mkIf;
  cfg = config.custom.server.ups;
in
{
  config = mkMerge [
    (mkIf cfg.enable {
      sops.secrets."nut/monitor" = { };
    })

    (mkIf (cfg.enable && cfg.mode == "client") {
      power.ups = {
        enable = true;
        mode = "netclient";
        upsmon.monitor.primary = {
          passwordFile = config.sops.secrets."nut/monitor".path;
          # the tailscale service, wherever it's hosted
          system = "primary@nut";
          type = "secondary";
          user = "monitor";
        };
      };
    })

    (mkIf (cfg.enable && cfg.mode == "server") {
      sops.secrets."nut/admin".sopsFile = config.custom.base.secrets.system;

      services.prometheus.exporters.nut = {
        enable = true;
        listenAddress = "127.0.0.1";
      };
      custom.server.alloy.scrapes.ups = {
        address = "127.0.0.1:9199";
        metricsPath = "/ups_metrics";
      };

      systemd = {
        services.upsdrv.serviceConfig = {
          # the driver sometimes fails to initialize the ups on first start
          Restart = "on-failure";
          RestartSec = "10s";
        };
        # stale pid files survive reboots and make the driver kill an unrelated process
        tmpfiles.rules = [ "r /var/lib/nut/*.pid" ];
      };
      services.tailscale.serve = {
        enable = true;
        services.nut.endpoints."tcp:3493" = "tcp://127.0.0.1:3493";
      };
      power.ups = {
        enable = true;
        mode = "netserver";
        ups.primary = {
          driver = "usbhid-ups";
          port = "auto";
          directives = [
            "pollfreq = 5"
            "productid = 0601"
            "pollonly"
          ];
        };
        users.admin = {
          passwordFile = config.sops.secrets."nut/admin".path;
          actions = [
            "SET"
            "FSD"
          ];
          instcmds = [ "ALL" ];
          upsmon = "primary";
        };
        users.monitor = {
          passwordFile = config.sops.secrets."nut/monitor".path;
          upsmon = "secondary";
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

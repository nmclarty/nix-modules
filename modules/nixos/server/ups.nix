{
  lib,
  flake,
  config,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  cfg = config.custom.server.ups;
  # find the hostname of the first computer that is a ups server
  upsServer = lib.findFirst (
    name:
    with flake.nixosConfigurations.${name}.config;
    custom ? server && custom.server.ups.enable && custom.server.ups.mode == "server"
  ) null (builtins.attrNames flake.nixosConfigurations);
in
{
  config = mkMerge [
    (mkIf (cfg.enable && cfg.mode == "client") {
      assertions = [
        {
          assertion = upsServer != null;
          message = "Ups client is enabled, but no ups server can be found.";
        }
      ];

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
      power.ups = {
        enable = true;
        mode = "netserver";
        upsd.listen = [ { address = "0.0.0.0"; } ];
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

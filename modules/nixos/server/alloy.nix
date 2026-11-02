{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf concatStrings mapAttrsToList;
  cfg = config.custom.server.alloy;
in
{
  config = mkIf cfg.enable {
    services.alloy = {
      enable = true;
      extraFlags = [ "--disable-reporting" ];
    };

    environment.etc."alloy/config.alloy".text = ''
      loki.relabel "journal" {
        forward_to = []

        // loki's service discovery doesn't know systemd's unit label
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "service_name"
        }
        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
      }

      loki.source.journal "default" {
        relabel_rules = loki.relabel.journal.rules
        labels        = { host = constants.hostname }
        forward_to    = [loki.write.default.receiver]
      }

      loki.write "default" {
        endpoint {
          // the tailscale service, wherever it's hosted
          url = "http://loki:3100/loki/api/v1/push"
        }
      }

      prometheus.exporter.unix "default" {
        enable_collectors = ["systemd"]
      }

      prometheus.scrape "unix" {
        targets    = prometheus.exporter.unix.default.targets
        forward_to = [prometheus.remote_write.default.receiver]
      }

      prometheus.remote_write "default" {
        endpoint {
          url = "http://prometheus:9090/api/v1/write"
        }
      }
    ''
    + concatStrings (
      mapAttrsToList (name: s: ''

        prometheus.scrape "${name}" {
          targets      = [{ __address__ = "${s.address}", instance = constants.hostname }]
          job_name     = "${name}"
          metrics_path = "${s.metricsPath}"
          forward_to   = [prometheus.remote_write.default.receiver]
        }
      '') cfg.scrapes
    );
  };
}

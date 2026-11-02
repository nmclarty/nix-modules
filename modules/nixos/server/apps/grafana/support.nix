{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.grafana;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    # neither has auth of its own, so access is left to the tailnet's grants
    services.tailscale.serve = {
      enable = true;
      services.loki.endpoints."tcp:3100" = "tcp://127.0.0.1:3100";
      services.prometheus.endpoints."tcp:9090" = "tcp://127.0.0.1:9090";
    };

    virtualisation.quadlet.containers = {
      grafana-loki.containerConfig = {
        image = "docker.io/grafana/loki:${cfg.tags.loki}";
        user = "${id}:${id}";
        exec = [ "-config.file=/etc/loki/config.yaml" ];
        volumes = [
          "${config.sops.templates."grafana/loki.yaml".path}:/etc/loki/config.yaml:ro"
          "/srv/grafana/loki:/loki"
        ];
        networks = [ "grafana-support.network" ];
        # published ports bypass the firewall, so binding to loopback keeps it off the lan
        publishPorts = [ "127.0.0.1:3100:3100" ];
        # the image has no shell; a "CMD" prefix makes podman exec this directly
        healthCmd = "CMD /usr/bin/loki -health";
      };

      grafana-prometheus.containerConfig = {
        image = "docker.io/prom/prometheus:${cfg.tags.prometheus}";
        user = "${id}:${id}";
        exec = [
          # the image's defaults, which setting exec replaces
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          # alloy pushes instead of being scraped
          "--web.enable-remote-write-receiver"
          "--storage.tsdb.retention.time=30d"
        ];
        volumes = [ "/srv/grafana/prometheus:/prometheus" ];
        networks = [ "grafana-support.network" ];
        publishPorts = [ "127.0.0.1:9090:9090" ];
        healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:9090/-/ready";
      };
    };
  };
}

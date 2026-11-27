{ lib, config, ... }:
let
  inherit (lib) mkIf;
  inherit (config.virtualisation.quadlet) networks;
  cfg = config.custom.apps.grafana;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    # none has auth of its own, so access is left to the tailnet's grants
    services.tailscale.serve = {
      enable = true;
      services = {
        loki.endpoints."tcp:3100" = "tcp://127.0.0.1:3100";
        prometheus.endpoints."tcp:9090" = "tcp://127.0.0.1:9090";
        grafana-mcp.endpoints."tcp:80" = "tcp://127.0.0.1:8000";
      };
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
        networks = [ networks.grafana-support.ref ];
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
        networks = [ networks.grafana-support.ref ];
        publishPorts = [ "127.0.0.1:9090:9090" ];
        healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:9090/-/ready";
      };

      grafana-mcp.containerConfig = {
        image = "docker.io/grafana/mcp-grafana:${cfg.tags.mcp}";
        user = "${id}:${id}";
        exec = [
          "--allowed-hosts=grafana-mcp"
          "--transport=streamable-http"
          "--disable-write"
        ];
        environments.GRAFANA_URL = "http://grafana:3000";
        secrets = [ "grafana__mcp__token,type=env,target=GRAFANA_SERVICE_ACCOUNT_TOKEN" ];
        networks = [ networks.grafana-support.ref ];
        publishPorts = [ "127.0.0.1:8000:8000" ];
        # the image has no wget or curl
        healthCmd = "bash -c ': </dev/tcp/127.0.0.1/8000'";
      };
    };
  };
}

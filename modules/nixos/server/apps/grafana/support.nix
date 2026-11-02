{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.grafana;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    # loki has no auth of its own, so access is left to the tailnet's grants
    services.tailscale.serve = {
      enable = true;
      services.loki.endpoints."tcp:3100" = "tcp://127.0.0.1:3100";
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
    };
  };
}

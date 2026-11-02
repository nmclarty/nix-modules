{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.grafana;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
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
        # the image has no shell; a "CMD" prefix makes podman exec this directly
        healthCmd = "CMD /usr/bin/loki -health";
      };
    };
  };
}

{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.traefik;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    virtualisation.quadlet.containers = {
      socket-proxy.containerConfig = {
        image = "lscr.io/linuxserver/socket-proxy:${cfg.tags.socket-proxy}";
        autoUpdate = "registry";
        readOnly = true;
        tmpfses = [ "/tmp" ];
        environments = {
          CONTAINERS = "1";
          LOG_LEVEL = "notice";
        };
        volumes = [ "/var/run/podman/podman.sock:/var/run/docker.sock:ro" ];
        networks = [ "socket-proxy.network" ];
        healthCmd = "wget -O - -q -T 5 http://127.0.0.1:2375/_ping";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };

      ddns-updater.containerConfig = {
        image = "docker.io/qmcgaw/ddns-updater:${cfg.tags.ddns-updater}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        volumes = [
          "${config.sops.templates."ddns-updater/config.json".path}:/updater/data/config.json:ro"
          "/srv/ddns-updater:/updater/data"
        ];
        networks = [ "exposed.network" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.ddns-updater.middlewares" = "tinyauth";
        };
      };
    };
  };
}

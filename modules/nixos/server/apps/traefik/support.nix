{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.traefik;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    custom.apps.traefik.routes.ddns-updater = {
      container = "ddns-updater";
      port = 8000;
      homepage = {
        group = "Proxy";
        name = "DDNS Updater";
      };
    };

    virtualisation.quadlet.containers.ddns-updater.containerConfig = {
      image = "docker.io/qmcgaw/ddns-updater:${cfg.tags.ddns-updater}";
      user = "${id}:${id}";
      volumes = [
        "${config.sops.templates."ddns-updater/config.json".path}:/updater/data/config.json:ro"
        "/srv/traefik/ddns-updater:/updater/data"
      ];
    };
  };
}

{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.homepage;
  id = toString cfg.user.id;
in
{
  imports = [ ./config.nix ];
  options.custom.apps.homepage = mkOptions {
    id = 2011;
    name = "homepage";
    tags.default = "v2";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [ "d /srv/homepage - ${id} ${id}" ];

    custom.apps.traefik.routes.homepage = {
      container = "homepage";
      port = 3000;
    };

    virtualisation.quadlet.containers.homepage.containerConfig = {
      image = "ghcr.io/gethomepage/homepage:${cfg.tags.default}";
      user = "${id}:${id}";
      environments = {
        LOG_TARGETS = "stdout"; # removes logpath dir in /app/config
        HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.custom.apps.settings.domain}";
      };
      volumes = [
        "/srv/homepage:/app/config"
        "${config.sops.templates."homepage/bookmarks.yaml".path}:/app/config/bookmarks.yaml:ro"
        "${config.sops.templates."homepage/services.yaml".path}:/app/config/services.yaml:ro"
        "${config.sops.templates."homepage/settings.yaml".path}:/app/config/settings.yaml:ro"
        "${config.sops.templates."homepage/widgets.yaml".path}:/app/config/widgets.yaml:ro"
      ];
      healthCmd = "wget -O - -q -T 5 127.0.0.1:3000/api/healthcheck";
    };
  };
}

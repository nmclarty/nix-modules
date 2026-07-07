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
  imports = [
    ./support.nix
    ./config.nix
  ];
  options.custom.apps.homepage = mkOptions {
    id = 2011;
    name = "homepage";
    tags = {
      default = "latest";
      socket-proxy = "latest";
    };
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [ "d /srv/homepage - ${id} ${id}" ];

    virtualisation.quadlet = {
      containers.homepage.containerConfig = {
        image = "ghcr.io/gethomepage/homepage:${cfg.tags.default}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments.HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.custom.apps.settings.domain}";
        volumes = [
          "/srv/homepage:/app/config"
          "${config.sops.templates."homepage/docker.yaml".path}:/app/config/docker.yaml:ro"
        ];
        networks = [
          "exposed"
          "homepage"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.homepage.middlewares" = "tinyauth";
        };
        healthCmd = "wget -O - -q -T 5 127.0.0.1:3000/api/healthcheck";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };

      networks.homepage.networkConfig.internal = true;
    };
  };
}

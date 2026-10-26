{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.beszel;
  id = toString cfg.user.id;
in
{
  options.custom.apps.beszel = mkOptions {
    id = 2009;
    name = "beszel";
    tags.default = "latest";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/beszel - ${id} ${id}"
    ];

    custom.apps.traefik.routes.beszel = {
      container = "beszel";
      port = 8090;
      public = true;
      homepage.group = "Management";
    };

    virtualisation.quadlet.containers.beszel.containerConfig = {
      image = "docker.io/henrygd/beszel:${cfg.tags.default}";
      user = "${id}:${id}";
      environments = {
        APP_URL = "https://beszel.${config.custom.apps.settings.domain}";
        DISABLE_PASSWORD_AUTH = "true";
        USER_CREATION = "true";
      };
      volumes = [ "/srv/beszel:/beszel_data" ];
      publishPorts = [ "8090:8090" ]; # for server connections
    };
  };
}

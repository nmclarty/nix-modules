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

    virtualisation.quadlet.containers.beszel.containerConfig = {
      image = "docker.io/henrygd/beszel:${cfg.tags.default}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      environments = {
        APP_URL = "https://beszel.${config.custom.apps.settings.domain}";
        DISABLE_PASSWORD_AUTH = "true";
        USER_CREATION = "true";
      };
      volumes = [ "/srv/beszel:/beszel_data" ];
      networks = [ "exposed.network" ];
      publishPorts = [ "8090:8090" ]; # for server connections
      labels = {
        "traefik.enable" = "true";
        "homepage.group" = "Management";
        "homepage.name" = "Beszel";
        "homepage.icon" = "beszel.svg";
        "homepage.href" = "https://beszel.${config.custom.apps.settings.domain}";
      };
    };
  };
}

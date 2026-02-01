{ lib, customLib, config, ... }:
let
  inherit (customLib) mkContainerUser;
  cfg = config.custom.apps.beszel;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/beszel - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.beszel.containerConfig = {
      image = "docker.io/henrygd/beszel:${cfg.tag}";
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
      labels = { "traefik.enable" = "true"; }; # for user access
    };
  };
}

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
  options.custom.apps.homepage = mkOptions {
    id = 2011;
    name = "homepage";
    tags.default = "latest";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [ "d /srv/homepage - ${id} ${id}" ];

    virtualisation.quadlet.containers.homepage.containerConfig = {
      image = "ghcr.io/gethomepage/homepage:${cfg.tags.default}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      environments.HOMEPAGE_ALLOWED_HOSTS = "homepage.${config.custom.apps.settings.domain}";
      volumes = [ "/srv/homepage:/app/config" ];
      networks = [ "exposed" ];
      labels."traefik.enable" = "true";
    };
  };
}

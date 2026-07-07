{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.jellyfin;
  id = toString cfg.user.id;
in
{
  options.custom.apps.jellyfin = mkOptions {
    id = 2008;
    name = "jellyfin";
    tags.default = "latest";
  };

  config = mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [ "d /srv/jellyfin - ${id} ${id}" ];

    virtualisation.quadlet.containers.jellyfin.containerConfig = {
      image = "ghcr.io/jellyfin/jellyfin:${cfg.tags.default}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      devices = [ "/dev/dri:/dev/dri" ];
      volumes = [
        "/srv/jellyfin:/config"
        "jellyfin-cache:/cache"
        "/tank/media:/media:ro"
      ];
      networks = [ "exposed" ];
      labels."traefik.enable" = "true";
      healthCmd = "curl -fs http://127.0.0.1:8096/health";
      healthStartupCmd = "sleep 10";
      healthOnFailure = "kill";
    };
  };
}

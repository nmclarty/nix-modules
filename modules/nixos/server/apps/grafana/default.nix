{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.grafana;
  id = toString cfg.user.id;
in
{
  imports = [ ./config.nix ];
  options.custom.apps.grafana = mkOptions {
    id = 2012;
    name = "grafana";
    # no major-only tags are published
    tags.default = "13.3";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/grafana - ${id} ${id}"
    ];

    custom.apps.traefik.routes.grafana = {
      container = "grafana";
      port = 3000;
      public = true;
      homepage.group = "Management";
    };

    virtualisation.quadlet.containers.grafana.containerConfig = {
      image = "docker.io/grafana/grafana:${cfg.tags.default}";
      user = "${id}:${id}";
      volumes = [
        "${config.sops.templates."grafana/grafana.ini".path}:/etc/grafana/grafana.ini:ro"
        "/srv/grafana:/var/lib/grafana"
      ];
      healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:3000/api/health";
    };
  };
}

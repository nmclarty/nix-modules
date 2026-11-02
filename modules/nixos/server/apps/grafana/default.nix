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
  imports = [
    ./config.nix
    ./support.nix
  ];
  options.custom.apps.grafana = mkOptions {
    id = 2012;
    name = "grafana";
    tags = {
      default = "13.3";
      loki = "3";
      prometheus = "v3";
    };
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/grafana/data - ${id} ${id}"
      "d /srv/grafana/loki - ${id} ${id}"
      "d /srv/grafana/prometheus - ${id} ${id}"
    ];

    custom.apps.traefik.routes.grafana = {
      container = "grafana";
      port = 3000;
      public = true;
      homepage.group = "Management";
    };

    virtualisation.quadlet = {
      containers.grafana.containerConfig = {
        image = "docker.io/grafana/grafana:${cfg.tags.default}";
        user = "${id}:${id}";
        volumes = [
          "${config.sops.templates."grafana/grafana.ini".path}:/etc/grafana/grafana.ini:ro"
          "${
            config.sops.templates."grafana/datasources.yaml".path
          }:/etc/grafana/provisioning/datasources/datasources.yaml:ro"
          "/srv/grafana/data:/var/lib/grafana"
        ];
        networks = [ "grafana-support.network" ];
        healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:3000/api/health";
      };
      networks.grafana-support = { };
    };
  };
}

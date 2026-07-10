{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser mkDeps;
  cfg = config.custom.apps.traefik;
  id = toString cfg.user.id;
in
{
  imports = [
    ./config.nix
    ./support.nix
  ];
  options.custom.apps.traefik = mkOptions {
    id = 2004;
    name = "traefik";
    tags = {
      default = "v3";
      socket-proxy = "latest";
      ddns-updater = "latest";
    };
  };

  config = lib.mkIf cfg.enable {
    # user
    users = mkUser { inherit (cfg.user) name id; };

    # dirs
    systemd.tmpfiles.rules = [
      "d /srv/traefik/data - ${id} ${id}"
      "f /srv/traefik/data/access.log 0600 ${id} ${id}"
      "d /srv/traefik/ddns-updater - ${id} ${id}"
    ];

    # containers
    virtualisation.quadlet = {
      containers.traefik = {
        containerConfig = {
          image = "docker.io/library/traefik:${cfg.tags.default}";
          autoUpdate = "registry";
          user = "${id}:${id}";
          secrets = [
            "traefik__porkbun__api_key,type=env,target=PORKBUN_API_KEY"
            "traefik__porkbun__secret_key,type=env,target=PORKBUN_SECRET_API_KEY"
          ];
          volumes = [
            "${config.sops.templates."traefik/traefik.yaml".path}:/etc/traefik/traefik.yaml:ro"
            "${config.sops.templates."traefik/dynamic.yaml".path}:/etc/traefik/dynamic.yaml:ro"
            "/srv/traefik/data:/data"
          ];
          sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
          publishPorts = [
            "80:80" # main http
            "443:443" # main https
          ];
          networks = [
            "exposed:ip=10.90.0.2"
            "traefik"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.traefik.service" = "api@internal";
            "traefik.http.routers.traefik.middlewares" = "tinyauth";
            "homepage.group" = "Proxy";
            "homepage.name" = "Traefik";
            "homepage.icon" = "traefik.svg";
            "homepage.href" = "https://traefik.${config.custom.apps.settings.domain}";
          };
          healthCmd = "traefik healthcheck";
          healthStartupCmd = "sleep 10";
          healthOnFailure = "kill";
        };
        unitConfig = mkDeps [
          "socket-proxy"
          "ddns-updater"
        ];
      };

      networks = {
        traefik.networkConfig.internal = true;
        exposed.networkConfig = {
          subnets = [ "10.90.0.0/24" ];
          ipRanges = [ "10.90.0.5-10.90.0.254" ];
        };
      };
    };
  };
}

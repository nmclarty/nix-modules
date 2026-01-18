{ inputs, lib, config, ... }:
let
  inherit (inputs.nix-helpers.lib) mkContainerUser mkContainerDeps;
  cfg = config.apps.traefik;
  id = toString cfg.user.id;
in
{
  imports = [ ./config.nix ];
  config = lib.mkIf cfg.enable {
    # user
    users = mkContainerUser { inherit (cfg.user) name id; };

    # dirs
    systemd.tmpfiles.rules = [
      "d /srv/traefik - ${id} ${id}"
      "d /srv/ddns-updater - ${id} ${id}"
    ];

    # containers
    virtualisation.quadlet = {
      containers = {
        traefik = {
          containerConfig = {
            image = "docker.io/library/traefik:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            secrets = [
              "traefik__porkbun__api_key,type=env,target=PORKBUN_API_KEY"
              "traefik__porkbun__secret_key,type=env,target=PORKBUN_SECRET_API_KEY"
            ];
            volumes = [
              "${config.sops.templates."traefik/traefik.yaml".path}:/etc/traefik/traefik.yaml:ro"
              "${config.sops.templates."traefik/dynamic.yaml".path}:/etc/traefik/dynamic.yaml:ro"
              "/srv/traefik:/data"
            ];
            sysctl."net.ipv4.ip_unprivileged_port_start" = "80";
            publishPorts = [
              "80:80" # main http
              "443:443" # main https
            ];
            networks = [ "socket-proxy" "exposed:ip=10.90.0.2" ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.traefik.service" = "api@internal";
              "traefik.http.routers.traefik.middlewares" = "tinyauth";
            };
            healthCmd = "traefik healthcheck";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          unitConfig = mkContainerDeps [ "socket-proxy" ];
        };

        socket-proxy = {
          containerConfig = {
            image = "lscr.io/linuxserver/socket-proxy:latest";
            autoUpdate = "registry";
            readOnly = true;
            tmpfses = [ "/tmp" ];
            environments = {
              CONTAINERS = "1";
              LOG_LEVEL = "notice";
            };
            volumes = [ "/var/run/podman/podman.sock:/var/run/docker.sock:ro" ];
            networks = [ "socket-proxy.network" ];
            healthCmd = "wget -O - -q -T 5 http://127.0.0.1:2375/_ping";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
        };

        ddns-updater = {
          containerConfig = {
            image = "docker.io/qmcgaw/ddns-updater:latest";
            autoUpdate = "registry";
            user = "${id}:${id}";
            volumes = [
              "${config.sops.templates."ddns-updater/config.json".path}:/updater/data/config.json:ro"
              "/srv/ddns-updater:/updater/data"
            ];
            networks = [ "exposed.network" ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.ddns-updater.middlewares" = "tinyauth";
            };
          };
        };
      };
      networks = {
        socket-proxy.networkConfig.internal = true;
        exposed.networkConfig = {
          subnets = [ "10.90.0.0/24" ];
          ipRanges = [ "10.90.0.5-10.90.0.254" ];
        };
      };
    };
  };
}

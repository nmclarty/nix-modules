{
  lib,
  pkgs,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser mkDeps;
  cfg = config.custom.apps.traefik;
  id = toString cfg.user.id;
  # host services are reached through the exposed network's gateway
  gateway = "10.90.0.1";
in
{
  imports = [
    ./config.nix
    ./support.nix
  ];
  options.custom.apps.traefik =
    mkOptions {
      id = 2004;
      name = "traefik";
      tags = {
        default = "v3";
        socket-proxy = "latest";
        ddns-updater = "latest";
      };
    }
    // {
      routes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                host = lib.mkOption {
                  type = lib.types.str;
                  default = "${name}.${config.custom.apps.settings.domain}";
                  description = "The hostname to route.";
                };
                address = lib.mkOption {
                  type = lib.types.str;
                  default = gateway;
                  description = "The address of the service to proxy to, defaulting to this host.";
                };
                port = lib.mkOption {
                  type = lib.types.port;
                  description = "The port of the service to proxy to.";
                };
                middlewares = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Names of middlewares to apply to the route.";
                };
              };
            }
          )
        );
        default = { };
        description = "Routes to services outside of podman, on this host or another.";
      };
      dynamicConfig = lib.mkOption {
        inherit (pkgs.formats.json { }) type;
        default = { };
        description = "Traefik dynamic configuration, rendered as a sops template so it can contain placeholders.";
      };
    };

  config = lib.mkIf cfg.enable {
    # traefik rejects empty routers/services maps, so only set them when there are routes
    custom.apps.traefik.dynamicConfig.http = lib.mkIf (cfg.routes != { }) {
      routers = lib.mapAttrs (name: r: {
        rule = "Host(`${r.host}`)";
        service = name;
        inherit (r) middlewares;
      }) cfg.routes;
      services = lib.mapAttrs (_: r: {
        loadBalancer.servers = [ { url = "http://${r.address}:${toString r.port}"; } ];
      }) cfg.routes;
    };
    # remote routes are firewalled on their own host instead
    networking.firewall.interfaces.podman-exposed.allowedTCPPorts = lib.mapAttrsToList (_: r: r.port) (
      lib.filterAttrs (_: r: r.address == gateway) cfg.routes
    );

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
        };
        unitConfig = mkDeps [
          "socket-proxy"
          "ddns-updater"
        ];
      };

      networks = {
        traefik.networkConfig.internal = true;
        exposed.networkConfig = {
          interfaceName = "podman-exposed";
          subnets = [ "10.90.0.0/24" ];
          gateways = [ "10.90.0.1" ];
          ipRanges = [ "10.90.0.5-10.90.0.254" ];
        };
      };
    };
  };
}

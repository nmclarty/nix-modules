{
  lib,
  pkgs,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser mkDeps;
  inherit (lib)
    all
    attrValues
    filter
    filterAttrs
    findFirst
    genAttrs
    listToAttrs
    mapAttrs
    mkMerge
    nameValuePair
    unique
    ;
  cfg = config.custom.apps.traefik;
  id = toString cfg.user.id;
  inherit (config.custom.apps.settings) domain;
  # podman resolves this to the host inside containers, so host routes need no fixed addressing
  hostAddress = "host.containers.internal";

  routes = attrValues cfg.routes;
  inherit (config.virtualisation.quadlet) containers;
  isHostRoute = r: r.container == null && r.pod == null && r.address == null;
  targetOf =
    r:
    findFirst (x: x != null) null [
      r.container
      r.pod
    ];
  ingressOf = r: if targetOf r != null then "${targetOf r}-ingress" else null;
  ingressRoutes = filter (r: ingressOf r != null) routes;
  ingressNetworks = unique (map ingressOf ingressRoutes);
  routedContainers = unique (map (r: r.container) (filter (r: r.container != null) routes));
  routedPods = unique (map (r: r.pod) (filter (r: r.pod != null) routes));
  addressOf =
    r:
    findFirst (x: x != null) hostAddress [
      (targetOf r)
      r.address
    ];
  proxiedRoutes = filterAttrs (_: r: r.service == null) cfg.routes;
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
        ddns-updater = "latest";
      };
    }
    // {
      routes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, config, ... }:
            {
              options = {
                host = lib.mkOption {
                  type = lib.types.str;
                  default = "${name}.${domain}";
                  description = "The hostname to route.";
                };
                rule = lib.mkOption {
                  type = lib.types.str;
                  default = "Host(`${config.host}`)";
                  description = "The traefik router rule, matching the host by default.";
                };
                container = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "A container to route to, which gets its own ingress network shared with traefik.";
                };
                pod = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "A pod to route to, which gets its own ingress network shared with traefik.";
                };
                address = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "The address of a service on another host. Without a container, pod or address, this host is used.";
                };
                port = lib.mkOption {
                  type = with lib.types; nullOr port;
                  default = null;
                  description = "The port of the service to proxy to.";
                };
                service = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "An existing traefik service to use instead of proxying to a port (e.g. api@internal).";
                };
                middlewares = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Names of middlewares to apply to the route, after tinyauth (unless public).";
                };
                public = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "If the route skips tinyauth, for apps that handle their own authentication.";
                };
                homepage = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        group = lib.mkOption {
                          type = lib.types.str;
                          description = "The homepage group to list the route under.";
                        };
                        name = lib.mkOption {
                          type = lib.types.str;
                          default = lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name;
                          description = "The display name, defaulting to the capitalized route name.";
                        };
                        icon = lib.mkOption {
                          type = lib.types.str;
                          default = "${name}.svg";
                          description = "The homepage icon.";
                        };
                      };
                    }
                  );
                  default = null;
                  description = "How the route is listed on homepage, if at all.";
                };
                internal = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "If the container or pod's ingress network should have no internet access.";
                };
              };
            }
          )
        );
        default = { };
        description = "Routes to containers, pods, services on this host, or services on other hosts.";
      };
      ingressAddresses = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Fixed addresses for traefik on ingress networks, keyed by network, for apps that need to trust traefik's address.";
      };
      dynamicConfig = lib.mkOption {
        inherit (pkgs.formats.json { }) type;
        default = { };
        description = "Traefik dynamic configuration, rendered as a sops template so it can contain placeholders.";
      };
    };

  config = lib.mkIf cfg.enable {
    assertions =
      lib.concatLists (
        lib.mapAttrsToList (name: r: [
          {
            assertion =
              lib.length (
                filter (x: x != null) [
                  r.container
                  r.pod
                  r.address
                ]
              ) <= 1
              && (r.port == null) != (r.service == null);
            message = "Traefik route '${name}' must set at most one of container, pod or address, and exactly one of port or service.";
          }
          {
            # routing creates the container entry, so a typo shows up as one without an image
            assertion = r.container == null || containers.${r.container}.containerConfig.image != null;
            message = "Traefik route '${name}' targets container '${r.container}', which doesn't exist.";
          }
          {
            # pod members can't join networks themselves
            assertion = r.container == null || containers.${r.container}.containerConfig.pod == null;
            message = "Traefik route '${name}' targets container '${r.container}', which is in a pod, so route to the pod instead.";
          }
          {
            assertion =
              r.pod == null || lib.any (c: c.containerConfig.pod == "${r.pod}.pod") (attrValues containers);
            message = "Traefik route '${name}' targets pod '${r.pod}', which no container is in.";
          }
        ]) cfg.routes
      )
      ++ [
        {
          assertion = all (r: r.public) routes || config.custom.apps.tinyauth.enable;
          message = "Traefik routes that aren't public need tinyauth to be enabled.";
        }
      ];

    custom.apps.traefik = {
      routes.traefik = {
        service = "api@internal";
        homepage.group = "Proxy";
      };
      dynamicConfig.http = {
        routers = mapAttrs (name: r: {
          inherit (r) rule;
          middlewares = lib.optional (!r.public) "tinyauth" ++ r.middlewares;
          service = if r.service != null then r.service else name;
        }) cfg.routes;
        # traefik rejects an empty services map
        services = lib.mkIf (proxiedRoutes != { }) (
          mapAttrs (_: r: {
            loadBalancer.servers = [ { url = "http://${addressOf r}:${toString r.port}"; } ];
          }) proxiedRoutes
        );
      };
    };
    # container and remote routes don't go through the host, so only host routes are opened
    networking.firewall.interfaces.podman-traefik.allowedTCPPorts = map (r: r.port) (
      filter (r: isHostRoute r && r.port != null) routes
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
      containers = mkMerge [
        (genAttrs routedContainers (c: {
          containerConfig.networks = [ "${c}-ingress.network" ];
        }))
        {
          traefik = {
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
              # the uplink carries published ports and traefik's own traffic, so it has to stay first:
              # its default route is what host routes (and the firewall rule above) go through
              networks = [
                "traefik-uplink.network"
              ]
              ++ map (
                n:
                "${n}.network" + lib.optionalString (cfg.ingressAddresses ? ${n}) ":ip=${cfg.ingressAddresses.${n}}"
              ) ingressNetworks;
              healthCmd = "traefik healthcheck";
            };
            unitConfig = mkDeps [ "ddns-updater" ];
          };
        }
      ];

      pods = genAttrs routedPods (p: {
        podConfig = {
          networks = [ "${p}-ingress.network" ];
          # pod members don't resolve by name, so routes reach the pod through this alias
          networkAliases = [ p ];
        };
      });

      networks = mkMerge [
        (listToAttrs (
          map (
            n:
            nameValuePair n {
              networkConfig.internal = all (r: r.internal) (filter (r: ingressOf r == n) ingressRoutes);
            }
          ) ingressNetworks
        ))
        { traefik-uplink.networkConfig.interfaceName = "podman-traefik"; }
      ];
    };
  };
}

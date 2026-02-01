{ lib, customLib, config, ... }:
let
  inherit (customLib) mkContainerUser mkContainerDeps;
  cfg = config.custom.apps.immich;
  id = toString cfg.user.id;
in
{
  imports = [ ./support.nix ./config.nix ];
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/immich/library - ${id} ${id}"
      "d /srv/immich/redis - ${id} ${id}"
      "d /srv/immich/postgres - ${id} ${id}"
    ];

    virtualisation.quadlet = {
      containers = {
        immich = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-server:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              DB_PASSWORD_FILE = "/run/secrets/immich__postgres__password";
              REDIS_HOSTNAME = "immich-redis";
              DB_HOSTNAME = "immich-postgres";
              IMMICH_CONFIG_FILE = "/etc/immich/immich.json";
              IMMICH_WORKERS_INCLUDE = "api";
            };
            secrets = [ "immich__postgres__password,uid=${id},gid=${id},mode=0400" ];
            devices = [ "/dev/dri:/dev/dri" ];
            volumes = [
              "/srv/immich/library:/data"
              "${config.sops.templates."immich/config.json".path}:/etc/immich/immich.json:ro"
            ];
            networks = [ "immich.network" "exposed.network" ];
            labels = { "traefik.enable" = "true"; };
            healthCmd = "curl -fs http://127.0.0.1:2283/api/server/ping";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          unitConfig = mkContainerDeps [ "immich-redis" "immich-postgres" "immich-learning" "immich-microservices" ];
        };

        immich-microservices = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-server:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              DB_PASSWORD_FILE = "/run/secrets/immich__postgres__password";
              REDIS_HOSTNAME = "immich-redis";
              DB_HOSTNAME = "immich-postgres";
              IMMICH_CONFIG_FILE = "/etc/immich/immich.json";
              IMMICH_WORKERS_EXCLUDE = "api";
            };
            secrets = [ "immich__postgres__password,uid=${id},gid=${id},mode=0400" ];
            devices = [ "/dev/dri:/dev/dri" ];
            volumes = [
              "/srv/immich/library:/data"
              "${config.sops.templates."immich/config.json".path}:/etc/immich/immich.json:ro"
            ];
            networks = [ "immich.network" ];
            healthCmd = "true";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          unitConfig = mkContainerDeps [ "immich-redis" "immich-postgres" "immich-learning" ];
          serviceConfig.AllowedCPUs = config.custom.apps.settings.cpus;
        };

        immich-learning = {
          containerConfig = {
            image = "ghcr.io/immich-app/immich-machine-learning:${cfg.tag}-openvino";
            autoUpdate = "registry";
            userns = "auto:uidmapping=0:${id}:1,gidmapping=0:${id}:1";
            environments = { MACHINE_LEARNING_MODEL_INTRA_OP_THREADS = "2"; };
            podmanArgs = [ "--device-cgroup-rule=c 189:* rmw" ];
            devices = [ "/dev/dri:/dev/dri" ];
            volumes =
              [ "/dev/bus/usb:/dev/bus/usb" "immich-learning-cache:/cache" ];
            networks = [ "immich.network" ];
            healthCmd = "bash -c 'echo -n > /dev/tcp/127.0.0.1/3003'";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          serviceConfig.AllowedCPUs = config.custom.apps.settings.cpus;
        };
      };
      networks = { immich = { }; };
    };
  };
}

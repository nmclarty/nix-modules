{ lib, config, ... }:
let
  cfg = config.custom.apps.immich;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.quadlet.containers = {
      immich-redis.containerConfig = {
        image = "docker.io/valkey/valkey:8-bookworm";
        autoUpdate = "registry";
        user = "${id}:${id}";
        volumes = [ "/srv/immich/redis:/data" ];
        networks = [ "immich.network" ];
        healthCmd = "redis-cli ping";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
      immich-postgres.containerConfig = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
        autoUpdate = "registry";
        user = "${id}:${id}";
        shmSize = "128mb";
        environments = {
          POSTGRES_USER = "postgres";
          POSTGRES_DB = "immich";
          POSTGRES_PASSWORD_FILE = "/run/secrets/immich__postgres__password";
          POSTGRES_INITDB_ARGS = "--data-checksums";
        };
        secrets = [ "immich__postgres__password,uid=${id},gid=${id},mode=0400" ];
        volumes = [ "/srv/immich/postgres:/var/lib/postgresql/data" ];
        networks = [ "immich.network" ];
        healthCmd = "pg_isready -U postgres -d immich";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
    };
  };
}

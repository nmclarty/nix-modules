{ lib, config, ... }:
let
  cfg = config.custom.apps.immich;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.quadlet.containers = {
      immich-redis.containerConfig = {
        image = "docker.io/valkey/valkey:${cfg.tags.redis}";
        user = "${id}:${id}";
        volumes = [ "/srv/immich/redis:/data" ];
        networks = [ "immich-support.network" ];
        healthCmd = "redis-cli ping";
      };
      immich-postgres.containerConfig = {
        image = "ghcr.io/immich-app/postgres:${cfg.tags.postgres}";
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
        networks = [ "immich-support.network" ];
        healthCmd = "pg_isready -U postgres -d immich";
      };
    };
  };
}

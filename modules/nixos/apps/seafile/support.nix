{ lib, config, ... }:
let
  cfg = config.apps.seafile;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.quadlet = {
      containers = {
        seafile-mariadb = {
          containerConfig = {
            image = "docker.io/library/mariadb:10.11";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              MARIADB_AUTO_UPGRADE = "true";
              MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/seafile__mariadb__root_password";
            };
            secrets = [ "seafile__mariadb__root_password,uid=${id},gid=${id},mode=0400" ];
            volumes = [ "/srv/seafile/mariadb:/var/lib/mysql" ];
            networks = [ "seafile.network" ];
            healthCmd = "healthcheck.sh --connect --mariadbupgrade --innodb_initialized";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
        };

        seafile-redis = {
          containerConfig = {
            image = "docker.io/library/redis:8.2";
            autoUpdate = "registry";
            user = "${id}:${id}";
            entrypoint = [ "sh" "-c" "redis-server --requirepass $(cat /run/secrets/seafile__redis__password)" ];
            secrets = [ "seafile__redis__password,uid=${id},gid=${id},mode=0400" ];
            volumes = [ "/srv/seafile/redis:/data" ];
            networks = [ "seafile.network" ];
            healthCmd = "redis-cli ping";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
        };
      };
    };
  };
}

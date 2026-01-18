{ lib, config, ... }:
let
  cfg = config.apps.minecraft;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.quadlet = {
      containers = {
        minecraft-mariadb = {
          containerConfig = {
            image = "docker.io/library/mariadb:10.11";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              MARIADB_AUTO_UPGRADE = "true";
              MARIADB_DATABASE = "minecraft";
              MARIADB_USER = "minecraft";
              MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/minecraft__mariadb__root_password";
              MARIADB_PASSWORD_FILE = "/run/secrets/minecraft__mariadb__password";
            };
            secrets = [
              "minecraft__mariadb__root_password,uid=${id},gid=${id},mode=0400"
              "minecraft__mariadb__password,uid=${id},gid=${id},mode=0400"
            ];
            volumes = [ "/srv/minecraft/mariadb:/var/lib/mysql" ];
            networks = [ "minecraft.network" ];
            healthCmd = "healthcheck.sh --connect --mariadbupgrade --innodb_initialized";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
        };
      };
    };
  };
}

{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.forgejo;
  id = toString cfg.user.id;
in
{
  config = mkIf cfg.enable {
    virtualisation.quadlet.containers = {
      forgejo-mariadb.containerConfig = {
        image = "docker.io/library/mariadb:${cfg.tags.mariadb}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments = {
          MARIADB_AUTO_UPGRADE = "true";
          MARIADB_DATABASE = "forgejo";
          MARIADB_USER = "forgejo";
          MARIADB_ROOT_PASSWORD_FILE = "/run/secrets/forgejo__mariadb__root_password";
          MARIADB_PASSWORD_FILE = "/run/secrets/forgejo__mariadb__password";
        };
        secrets = [
          "forgejo__mariadb__root_password,uid=${id},gid=${id},mode=0400"
          "forgejo__mariadb__password,uid=${id},gid=${id},mode=0400"
        ];
        volumes = [ "/srv/forgejo/mariadb:/var/lib/mysql" ];
        networks = [ "forgejo" ];
        healthCmd = "healthcheck.sh --connect --mariadbupgrade --innodb_initialized";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
    };
  };
}

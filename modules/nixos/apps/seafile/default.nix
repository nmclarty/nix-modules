{ inputs, lib, config, ... }:
let
  inherit (inputs.helper-tools.lib) mkContainerUser mkContainerDeps;
  cfg = config.apps.seafile;
  id = toString cfg.user.id;
in
{
  imports = [ ./support.nix ./config.nix ];
  config = lib.mkIf cfg.enable {
    # user
    users = mkContainerUser { inherit (cfg.user) name id; };

    # dirs
    systemd.tmpfiles.rules = [
      "d /srv/seafile/logs - ${id} ${id}"
      "d /srv/seafile/nginx - ${id} ${id}"
      "d /srv/seafile/data - ${id} ${id}"
      "d /srv/seafile/data/logs - ${id} ${id}"
    ];

    # containers
    virtualisation.quadlet = {
      containers = {
        seafile = {
          containerConfig = {
            image = "docker.io/seafileltd/seafile-mc:${cfg.tag}";
            autoUpdate = "registry";
            userns = "auto:uidmapping=0:${id}:1,gidmapping=0:${id}:1";
            environments = rec {
              SEAFILE_MYSQL_DB_HOST = "seafile-mariadb";
              SEAFILE_MYSQL_DB_PORT = "3306";
              SEAFILE_MYSQL_DB_USER = "seafile";
              SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
              SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
              SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
              SEAFILE_SERVER_HOSTNAME = "seafile.${config.apps.settings.domain}";
              SEAFILE_SERVER_PROTOCOL = "https";
              SITE_ROOT = "/";
              NON_ROOT = "false";
              SEAFILE_LOG_TO_STDOUT = "true";
              ENABLE_SEADOC = "false";
              SEADOC_SERVER_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/sdoc-server";
              CACHE_PROVIDER = "redis";
              REDIS_HOST = "seafile-redis";
              REDIS_PORT = "6379";
              ENABLE_NOTIFICATION_SERVER = "true";
              INNER_NOTIFICATION_SERVER_URL = "http://seafile-notification:8083";
              NOTIFICATION_SERVER_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/notification";
              ENABLE_SEAFILE_AI = "false";
              SEAFILE_AI_SERVER_URL = "http://seafile-ai:8888";
              MD_FILE_COUNT_LIMIT = "100000";
            };
            secrets = [
              "seafile__mariadb__root_password,type=env,target=INIT_SEAFILE_MYSQL_ROOT_PASSWORD"
              "seafile__mariadb__password,type=env,target=SEAFILE_MYSQL_DB_PASSWORD"
              "seafile__admin_email,type=env,target=INIT_SEAFILE_ADMIN_EMAIL"
              "seafile__admin_password,type=env,target=INIT_SEAFILE_ADMIN_PASSWORD"
              "seafile__jwt_private_key,type=env,target=JWT_PRIVATE_KEY"
              "seafile__redis__password,type=env,target=REDIS_PASSWORD"
            ];
            volumes = [
              "/srv/seafile/logs:/shared/logs"
              "/srv/seafile/nginx:/shared/nginx"
              "/srv/seafile/data:/shared/seafile"
              "${config.sops.templates."seafile/seafile.conf".path}:/shared/seafile/conf/seafile.conf:ro"
              "${config.sops.templates."seafile/seahub_settings.py".path}:/shared/seafile/conf/seahub_settings.py:ro"
              "${config.sops.templates."seafile/seafevents.conf".path}:/shared/seafile/conf/seafevents.conf:ro"
              "${config.sops.templates."seafile/seafdav.conf".path}:/shared/seafile/conf/seafdav.conf:ro"
              "${config.sops.templates."seafile/gunicorn.conf.py".path}:/shared/seafile/conf/gunicorn.conf.py:ro"
            ];
            networks = [ "seafile.network" "exposed.network" ];
            labels = { "traefik.enable" = "true"; };
            healthCmd = "wget -O - -q -T 5 127.0.0.1:8000/api2/ping";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          unitConfig = mkContainerDeps [ "seafile-mariadb" "seafile-redis" ];
        };

        seafile-notification = {
          containerConfig = {
            image = "docker.io/seafileltd/notification-server:${cfg.tag}";
            autoUpdate = "registry";
            environments = {
              SEAFILE_MYSQL_DB_HOST = "seafile-mariadb";
              SEAFILE_MYSQL_DB_PORT = "3306";
              SEAFILE_MYSQL_DB_USER = "seafile";
              SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
              SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
              SEAFILE_LOG_TO_STDOUT = "true";
              NOTIFICATION_SERVER_LOG_LEVEL = "info";
            };
            secrets = [
              "seafile__mariadb__password,type=env,target=SEAFILE_MYSQL_DB_PASSWORD"
              "seafile__jwt_private_key,type=env,target=JWT_PRIVATE_KEY"
            ];
            volumes = [ "/srv/seafile/data/logs:/shared/seafile/logs" ];
            networks = [ "seafile.network" "exposed.network" ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.services.seafile-notification.loadbalancer.server.port" = "8083";
              "traefik.http.routers.seafile-notification.rule" =
                "Host(`seafile.${config.apps.settings.domain}`) && PathPrefix(`/notification`)";
            };
            healthCmd = "bash -c 'echo -n > /dev/tcp/127.0.0.1/8083'";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
          unitConfig = mkContainerDeps [ "seafile-mariadb" ];
        };
      };

      networks.seafile = { };
    };
  };
}

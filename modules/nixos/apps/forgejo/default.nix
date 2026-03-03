{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib) mkContainerUser mkContainerDeps;
  cfg = config.custom.apps.forgejo;
  id = toString cfg.user.id;
in
{
  imports = [ ./support.nix ];
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/forgejo/data - ${id} ${id}"
      "d /srv/forgejo/mariadb - ${id} ${id}"
    ];

    virtualisation.quadlet = {
      containers.forgejo = {
        containerConfig = {
          image = "codeberg.org/forgejo/forgejo:${cfg.tags.default}";
          autoUpdate = "registry";
          user = "${id}:${id}";
          environments = {
            # use mariadb instead of sqlite
            FORGEJO__database__DB_TYPE = "mysql";
            FORGEJO__database__HOST = "forgejo-mariadb:3306";
            FORGEJO__database__NAME = "forgejo";
            FORGEJO__database__USER = "forgejo";
            # set the domain (otherwise it generates it, and might be wrong)
            FORGEJO__server__DOMAIN = "forgejo.${config.custom.apps.settings.domain}";
            FORGEJO__server__ROOT_URL = "https://forgejo.${config.custom.apps.settings.domain}";
            # disable ssh (it seems buggy, issues with connection timeouts)
            FORGEJO____RUN_USER = "forgejo";
            FORGEJO__server__DISABLE_SSH = "true";
            # disable federated openid (not OIDC sso) signup
            FORGEJO__openid__ENABLE_OPENID_SIGNIN = "false";
            FORGEJO__openid__ENABLE_OPENID_SIGNUP = "false";
            # ensure emails are private
            FORGEJO__service__DEFAULT_KEEP_EMAIL_PRIVATE = "true";
          };
          secrets = [ "forgejo__mariadb__password,type=env,target=FORGEJO__database__PASSWD" ];
          volumes = [ "/srv/forgejo/data:/var/lib/gitea" ];
          networks = [
            "exposed"
            "forgejo"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.services.forgejo.loadbalancer.server.port" = "3000";
          };
          healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:3000";
          healthStartupCmd = "sleep 10";
          healthOnFailure = "kill";
        };
        unitConfig = mkContainerDeps [ "forgejo-mariadb" ];
      };
      networks.forgejo = { };
    };
  };
}

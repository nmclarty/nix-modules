{
  customLib,
  lib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.tinyauth;
  id = toString cfg.user.id;
in
{
  options.custom.apps.tinyauth = mkOptions {
    id = 2006;
    name = "tinyauth";
    tags.default = "v5";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/tinyauth - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.tinyauth = {
      containerConfig = {
        image = "ghcr.io/steveiliop56/tinyauth:${cfg.tags.default}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments = {
          # general
          TINYAUTH_APPURL = "https://tinyauth.${config.custom.apps.settings.domain}";
          TINYAUTH_LOG_LEVEL = "warn";
          TINYAUTH_OAUTH_AUTOREDIRECT = "pocketid";
          TINYAUTH_AUTH_SECURECOOKIE = "true";
          TINYAUTH_AUTH_TRUSTEDPROXIES = "10.90.0.2";
          TINYAUTH_AUTH_SESSIONEXPIRY = "604800";
          # pocket-id oauth
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTSECRETFILE = "/run/secrets/tinyauth__client_secret";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_AUTHURL = "https://pocket.${config.custom.apps.settings.domain}/authorize";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_TOKENURL = "https://pocket.${config.custom.apps.settings.domain}/api/oidc/token";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_USERINFOURL = "https://pocket.${config.custom.apps.settings.domain}/api/oidc/userinfo";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "https://tinyauth.${config.custom.apps.settings.domain}/api/oauth/callback/pocketid";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
          TINYAUTH_OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";
        };
        secrets = [
          "tinyauth__client_id,type=env,target=TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTID"
          "tinyauth__client_secret,uid=${id},gid=${id},mode=0400"
        ];
        volumes = [ "/srv/tinyauth:/data" ];
        networks = [ "exposed.network" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.middlewares.tinyauth.forwardauth.address" = "http://tinyauth:3000/api/auth/traefik";
        };
        healthCmd = "tinyauth healthcheck";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
    };
  };
}

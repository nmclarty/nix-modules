{ inputs, lib, config, ... }:
let
  inherit (inputs.helper-tools.lib) mkContainerUser;
  cfg = config.apps.tinyauth;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    # user
    users = mkContainerUser { inherit (cfg.user) name id; };

    # dirs
    systemd.tmpfiles.rules = [
      "d /srv/tinyauth - ${id} ${id}"
    ];

    # containers
    virtualisation.quadlet.containers.tinyauth = {
      containerConfig = {
        image = "ghcr.io/steveiliop56/tinyauth:${cfg.tag}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments = {
          # general
          APP_URL = "https://tinyauth.${config.apps.settings.domain}";
          LOG_LEVEL = "warn";
          OAUTH_AUTO_REDIRECT = "pocketid";
          SECURE_COOKIE = "true";
          TRUSTED_PROXIES = "10.90.0.2";
          # pocket-id oauth
          PROVIDERS_POCKETID_CLIENT_SECRET_FILE = "/run/secrets/tinyauth__client_secret";
          PROVIDERS_POCKETID_AUTH_URL = "https://pocket.${config.apps.settings.domain}/authorize";
          PROVIDERS_POCKETID_TOKEN_URL = "https://pocket.${config.apps.settings.domain}/api/oidc/token";
          PROVIDERS_POCKETID_USER_INFO_URL = "https://pocket.${config.apps.settings.domain}/api/oidc/userinfo";
          PROVIDERS_POCKETID_REDIRECT_URL = "https://tinyauth.${config.apps.settings.domain}/api/oauth/callback/pocketid";
          PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
          PROVIDERS_POCKETID_NAME = "Pocket ID";
        };
        secrets = [
          "tinyauth__client_id,type=env,target=PROVIDERS_POCKETID_CLIENT_ID"
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

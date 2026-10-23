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
  inherit (config.custom.apps.settings) domain;

  # supported oauth providers, keyed by the tinyauth provider id
  providers = {
    pocketid = {
      name = "Pocket ID";
      authUrl = "https://pocket.${domain}/authorize";
      tokenUrl = "https://pocket.${domain}/api/oidc/token";
      userInfoUrl = "https://pocket.${domain}/api/oidc/userinfo";
    };
    forgejo = {
      name = "Forgejo";
      authUrl = "https://forgejo.${domain}/login/oauth/authorize";
      tokenUrl = "https://forgejo.${domain}/login/oauth/access_token";
      userInfoUrl = "https://forgejo.${domain}/login/oauth/userinfo";
    };
  };
  provider = providers.${cfg.provider};
  envPrefix = "TINYAUTH_OAUTH_PROVIDERS_${lib.toUpper cfg.provider}";
in
{
  options.custom.apps.tinyauth =
    mkOptions {
      id = 2006;
      name = "tinyauth";
      tags.default = "v5";
    }
    // {
      provider = lib.mkOption {
        type = lib.types.enum (lib.attrNames providers);
        default = "pocketid";
        description = "The oauth provider to use as the source for tinyauth.";
      };
    };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/tinyauth - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.tinyauth = {
      containerConfig = {
        image = "ghcr.io/steveiliop56/tinyauth:${cfg.tags.default}";
        user = "${id}:${id}";
        environments = {
          # general
          TINYAUTH_APPURL = "https://tinyauth.${domain}";
          TINYAUTH_LOG_LEVEL = "warn";
          TINYAUTH_OAUTH_AUTOREDIRECT = cfg.provider;
          TINYAUTH_AUTH_SECURECOOKIE = "true";
          TINYAUTH_AUTH_TRUSTEDPROXIES = "10.90.0.2";
          TINYAUTH_AUTH_SESSIONEXPIRY = "604800";
          # oauth provider
          "${envPrefix}_CLIENTSECRETFILE" = "/run/secrets/tinyauth__client_secret";
          "${envPrefix}_AUTHURL" = provider.authUrl;
          "${envPrefix}_TOKENURL" = provider.tokenUrl;
          "${envPrefix}_USERINFOURL" = provider.userInfoUrl;
          "${envPrefix}_REDIRECTURL" = "https://tinyauth.${domain}/api/oauth/callback/${cfg.provider}";
          "${envPrefix}_SCOPES" = "openid email profile groups";
          "${envPrefix}_NAME" = provider.name;
        };
        secrets = [
          "tinyauth__client_id,type=env,target=${envPrefix}_CLIENTID"
          "tinyauth__client_secret,uid=${id},gid=${id},mode=0400"
        ];
        volumes = [ "/srv/tinyauth:/data" ];
        networks = [ "exposed.network" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.middlewares.tinyauth.forwardauth.address" = "http://tinyauth:3000/api/auth/traefik";
          # traefik should be the entrypoint, as there isn't any proxy in-front of this,
          # so explicitly remove all forward headers
          "traefik.http.middlewares.tinyauth.forwardauth.trustForwardHeader" = "false";
          # traefik recommends limiting the body size to prevent DoS so setting this
          # to 1MB for now...
          "traefik.http.middlewares.tinyauth.forwardauth.maxBodySize" = "1048576";
          "traefik.http.middlewares.tinyauth.forwardauth.maxResponseBodySize" = "1048576";
          "homepage.group" = "Proxy";
          "homepage.name" = "Tinyauth";
          "homepage.icon" = "tinyauth.svg";
          "homepage.href" = "https://tinyauth.${domain}";
        };
        healthCmd = "tinyauth healthcheck";
      };
    };
  };
}

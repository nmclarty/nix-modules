{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.pocket;
  id = toString cfg.user.id;
in
{
  options.custom.apps.pocket = mkOptions {
    id = 2005;
    name = "pocket";
    tags.default = "v2";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/pocket - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.pocket = {
      containerConfig = {
        image = "ghcr.io/pocket-id/pocket-id:${cfg.tags.default}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments = {
          APP_URL = "https://pocket.${config.custom.apps.settings.domain}";
          TRUST_PROXY = "true";
          MAXMIND_LICENSE_KEY_FILE = "/run/secrets/pocket__maxmind_licence_key";
          ENCRYPTION_KEY_FILE = "/run/secrets/pocket__encryption_key";
          UI_CONFIG_DISABLED = "true";
          # UI config
          SESSION_DURATION = "131400";
          HOME_PAGE_URL = "/settings/apps";
          DISABLE_ANIMATIONS = "true";
          EMAILS_VERIFIED = "true";
          ALLOW_USER_SIGNUPS = "withToken";
        };
        secrets = [
          "pocket__maxmind_licence_key,uid=${id},gid=${id},mode=0400"
          "pocket__encryption_key,uid=${id},gid=${id},mode=0400"
        ];
        volumes = [ "/srv/pocket:/app/data" ];
        networks = [ "exposed.network" ];
        labels = {
          "traefik.enable" = "true";
          "homepage.group" = "Management";
          "homepage.name" = "Pocket ID";
          "homepage.icon" = "pocket-id.svg";
          "homepage.href" = "https://pocket.${config.custom.apps.settings.domain}";
        };
        healthCmd = "/app/pocket-id healthcheck";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
    };
  };
}

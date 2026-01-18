{ inputs, lib, config, ... }:
let
  inherit (inputs.nix-helpers.lib) mkContainerUser;
  cfg = config.apps.pocket;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/pocket - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.pocket = {
      containerConfig = {
        image = "ghcr.io/pocket-id/pocket-id:${cfg.tag}";
        autoUpdate = "registry";
        user = "${id}:${id}";
        environments = {
          APP_URL = "https://pocket.${config.apps.settings.domain}";
          TRUST_PROXY = "true";
          MAXMIND_LICENSE_KEY_FILE = "/run/secrets/pocket__maxmind_licence_key";
          ENCRYPTION_KEY_FILE = "/run/secrets/pocket__encryption_key";
        };
        secrets = [
          "pocket__maxmind_licence_key,uid=${id},gid=${id},mode=0400"
          "pocket__encryption_key,uid=${id},gid=${id},mode=0400"
        ];
        volumes = [ "/srv/pocket:/app/data" ];
        networks = [ "exposed.network" ];
        labels = { "traefik.enable" = "true"; };
        healthCmd = "/app/pocket-id healthcheck";
        healthStartupCmd = "sleep 10";
        healthOnFailure = "kill";
      };
    };
  };
}

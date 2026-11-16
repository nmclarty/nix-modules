{
  lib,
  customLib,
  pkgs,
  config,
  ...
}:
let
  inherit (customLib.apps) getServices mkSecrets;
  cfg = config.custom.server.backup;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      resticprofile
    ];
    services = {
      helper-tools.backup = {
        enable = true;
        interval = "*-*-* 4:00:00";
        settings = {
          command = with pkgs; [
            "${resticprofile}/bin/resticprofile"
            "backup"
          ];
          services = getServices config;
          zpool = {
            name = "zroot";
            datasets = [
              "nixos"
              "srv"
            ];
          };
        };
      };
      # sanoid is managed by py-backup, so its timer is masked
      sanoid = {
        enable = true;
        templates.default = {
          hourly = 0;
          daily = 7;
          weekly = 4;
          monthly = 0;
          autosnap = true;
          autoprune = true;
        };
        datasets.zroot = {
          useTemplate = [ "default" ];
          recursive = true;
          processChildrenOnly = true;
        };
      };
    };
    sops = {
      secrets = mkSecrets [
        "restic/password"
        "restic/access_key"
        "restic/secret_key"
        "restic/rest_password"
      ] config.custom.base.secrets.system;
      templates."resticprofile/profiles.toml" = {
        path = "/etc/resticprofile/profiles.toml";
        content = ''
          version = "1"

          [groups]
          default = [ "remote", "local" ]

          [base]
          password-file = "${config.sops.secrets."restic/password".path}"
          force-inactive-lock = true
          initialize = true
          cache-dir = "/var/cache/restic"
          cleanup-cache = true
          pack-size = 64

          [base.backup]
          tag = "automatic"
          source = [ "nixos", "srv" ]
          source-base = "/.backup"
          source-relative = true

          [remote]
          inherit = "base"
          repository = "${cfg.remote}"

          [remote.env]
          AWS_ACCESS_KEY_ID = "${config.sops.placeholder."restic/access_key"}"
          AWS_SECRET_ACCESS_KEY = "${config.sops.placeholder."restic/secret_key"}"

          [remote.retention]
          after-backup = true
          tag = true
          prune = true
          keep-daily = 7
          keep-weekly = 4

          # no retention, since the rest-server is append-only and prunes its own repositories
          [local]
          inherit = "base"
          repository = "rest:http://restic:8000/${config.networking.hostName}/"

          [local.env]
          RESTIC_REST_USERNAME = "${config.networking.hostName}"
          RESTIC_REST_PASSWORD = "${config.sops.placeholder."restic/rest_password"}"
        '';
      };
    };
  };
}

{ lib, config, ... }:
let
  inherit (lib) mkMerge mkIf;
in
{
  config = mkMerge [
    {
      systemd.services.podman.environment.LOGGING = "--log-level=warn";
      virtualisation = {
        containers = {
          enable = true;
          containersConf.settings = {
            containers.tz = "local";
            engine.events_logger = "file";
          };
        };
        podman = {
          enable = true;
          autoPrune = {
            enable = true;
            flags = [ "--all" ];
          };
        };
        quadlet = {
          enable = true;
          autoUpdate = {
            enable = true;
            calendar = "weekly";
          };
        };
      };
      # this is required for rootful user namespacing (i.e. userns = "auto"; )
      users.users.containers = {
        isSystemUser = true;
        autoSubUidGidRange = true;
        group = "containers";
      };
      users.groups.containers = { };
    }

    (mkIf (builtins.pathExists config.custom.base.secrets.podman) {
      sops.secrets."podman-sops.yaml" = {
        sopsFile = config.custom.base.secrets.podman;
        key = "";
      };

      services.helper-tools.secret = {
        # only enabled if the host has a podman.yaml in its hosts/ dir;
        # services that depend on podman secrets will complain if the file is missing
        enable = true;
        settings.file = config.sops.secrets."podman-sops.yaml".path;
      };
    })
  ];
}

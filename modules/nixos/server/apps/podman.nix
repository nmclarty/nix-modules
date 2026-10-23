{ lib, config, ... }:
let
  inherit (lib)
    mkMerge
    mkIf
    mkDefault
    mkOption
    types
    ;
in
{
  # re-declaring the option merges this submodule into every container as defaults
  options.virtualisation.quadlet.containers = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        let
          hasHealth = config.containerConfig.healthCmd != null;
        in
        {
          config = {
            containerConfig = {
              noNewPrivileges = mkDefault true;
              # the unit only becomes active once healthy, so rebuilds and
              # dependent containers wait on it instead of racing the healthcheck
              notify = mkIf hasHealth (mkDefault "healthy");
              healthOnFailure = mkIf hasHealth (mkDefault "kill");
              healthStartPeriod = mkIf hasHealth (mkDefault "60s");
            };
            # exponential backoff (5s up to 5min) instead of systemd's 100ms
            serviceConfig = {
              RestartSec = mkDefault "5s";
              RestartSteps = mkDefault 6;
              RestartMaxDelaySec = mkDefault "5min";
            };
            # fail out after 6 starts; the window has to cover 6 health-check
            # kills (~150s each with the start period) plus the backoff delays,
            # or the counter resets before the limit is reached
            unitConfig = {
              StartLimitIntervalSec = mkDefault "30min";
              StartLimitBurst = mkDefault 6;
            };
          };
        }
      )
    );
  };

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

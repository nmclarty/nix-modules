{ lib, ... }:
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
  options.virtualisation.quadlet = {
    # re-declaring the option merges this submodule into every container as defaults
    containers = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            config = {
              containerConfig = mkMerge [
                {
                  autoUpdate = mkDefault "registry";
                  noNewPrivileges = mkDefault true;
                }
                (mkIf (config.containerConfig.healthCmd != null) {
                  # the unit only becomes active once healthy, so rebuilds and
                  # dependent containers wait on it instead of racing the healthcheck
                  notify = mkDefault "healthy";
                  healthOnFailure = mkDefault "kill";
                  healthStartPeriod = mkDefault "60s";
                  # no startup retries, since podman would restart the container
                  # itself, bypassing the backoff and start limit below
                  healthStartupCmd = mkDefault config.containerConfig.healthCmd;
                  healthStartupInterval = mkDefault "5s";
                })
              ];
              serviceConfig = {
                RestartSec = mkDefault "5s";
                RestartSteps = mkDefault 6;
                RestartMaxDelaySec = mkDefault "5min";
                # with notify = "healthy", quadlet-nix's 15min default would stall
                # rebuilds that long on a container that never gets healthy
                TimeoutStartSec = mkDefault "5min";
              };
              # the window has to cover 6 start timeouts plus the backoff delays,
              # or the counter resets before the limit is reached
              unitConfig = {
                StartLimitIntervalSec = mkDefault "1h";
                StartLimitBurst = mkDefault 6;
              };
            };
          }
        )
      );
    };

    # netavark doesn't isolate bridges by default, and the host forwards between them
    networks = mkOption {
      type = types.attrsOf (
        types.submodule {
          config.networkConfig.options.isolate = mkDefault "strict";
        }
      );
    };
  };
}

{ lib, config, ... }:
let
  inherit (lib)
    mkMerge
    mkIf
    mkDefault
    mkOption
    types
    ;
  inherit (config.custom.apps.images) lock refs;
in
{
  options.custom.apps.images = {
    lock = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Image digests keyed by image reference, appended to matching container images.
        Once set, every image in `refs` must be locked; `lock-images` maintains it.
      '';
    };
    refs = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      default = lib.pipe config.virtualisation.quadlet.containers [
        lib.attrValues
        (map (container: container.containerConfig.image))
        # Nix-built images are store paths, so there's nothing to lock
        (lib.filter (image: image != null && !builtins.hasContext image))
        (map (image: lib.head (lib.splitString "@" image)))
        lib.unique
      ];
      defaultText = "the registry images of all quadlet containers";
      description = "Image references of all containers, without their locked digests.";
    };
  };

  config.assertions =
    let
      missing = lib.filter (ref: !lock ? ${ref}) refs;
    in
    [
      {
        assertion = lock == { } || missing == [ ];
        message = "custom.apps.images.lock is missing ${lib.concatStringsSep ", " missing}; run `nix run .#lock-images`";
      }
    ];

  options.virtualisation.quadlet = {
    # re-declaring the option merges this submodule into every container as defaults
    containers = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            # quadlet-nix declares image without apply, so this declaration can add one
            options.containerConfig.image = mkOption {
              apply =
                ref:
                # Nix-built images are store paths, which can't be attribute names
                if ref == null || builtins.hasContext ref || !lock ? ${ref} then ref else "${ref}@${lock.${ref}}";
            };

            config = {
              containerConfig = mkMerge [
                {
                  # podman auto-update only follows tags, and a digest never changes anyway
                  autoUpdate = mkDefault (
                    if lib.hasInfix "@sha256:" (toString config.containerConfig.image) then null else "registry"
                  );
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

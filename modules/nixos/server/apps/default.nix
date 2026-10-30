{ lib, config, ... }:
let
  inherit (lib)
    any
    attrValues
    mkOption
    types
    ;
in
{
  imports = [
    ./podman.nix
    ./quadlet.nix
    ./beszel
    ./forgejo
    ./garage
    ./homepage
    ./immich
    ./jellyfin
    ./librespeed
    ./minecraft
    ./pocket
    ./seafile
    ./tinyauth
    ./traefik
  ];
  options.custom.apps = {
    enable = mkOption {
      type = types.bool;
      # skip this option itself, since its default reads the others
      default = any (app: app.enable or false) (attrValues (removeAttrs config.custom.apps [ "enable" ]));
      defaultText = "true if any app is enabled";
      description = "If shared app infrastructure (podman) should be enabled.";
    };
    settings = {
      domain = mkOption {
        type = types.str;
        default = "example.com";
        description = "The domain name to use for all apps.";
      };
      cpus = mkOption {
        type = types.str;
        default = "";
        description = "The cpu core(s) that performance-intensive apps will be limited to.";
      };
    };
  };
}

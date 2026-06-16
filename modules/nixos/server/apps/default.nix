{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./podman.nix
    ./beszel
    ./forgejo
    ./garage
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

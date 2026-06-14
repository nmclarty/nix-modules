{
  customLib,
  lib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions;
  cfg = config.custom.apps.librespeed;
in
{
  options.custom.apps.librespeed = mkOptions {
    id = 2010;
    name = "librespeed";
    tags.default = "latest";
  };

  config = lib.mkIf cfg.enable {
    # users = mkUser { inherit (cfg.user) name id; }; # see userns below, not needed

    virtualisation.quadlet = {
      containers.librespeed.containerConfig = {
        image = "ghcr.io/librespeed/speedtest:${cfg.tags.default}";
        autoUpdate = "registry";
        userns = "auto"; # container doesn't work with user set, so it gets namespaced
        environments = {
          MODE = "standalone";
        };
        networks = [ "exposed" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.services.librespeed.loadbalancer.server.port" = "8080";
        };
      };
    };
  };
}

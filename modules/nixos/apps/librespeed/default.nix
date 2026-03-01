{
  customLib,
  lib,
  config,
  ...
}:
let
  inherit (customLib) mkContainerUser;
  cfg = config.custom.apps.librespeed;
in
{
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

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

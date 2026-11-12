{
  customLib,
  lib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.librespeed;
  id = toString cfg.user.id;
in
{
  options.custom.apps.librespeed = mkOptions {
    id = 2010;
    name = "librespeed";
    tags.default = "6";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    custom.apps.traefik.routes.librespeed = {
      container = "librespeed";
      port = 8080;
      internal = true;
      public = true;
      homepage.group = "Proxy";
    };

    virtualisation.quadlet.containers.librespeed.containerConfig = {
      image = "ghcr.io/librespeed/speedtest:${cfg.tags.default}";
      # container doesn't work with user set, and runs as www-data (33)
      userns = "auto:uidmapping=33:${id}:1,gidmapping=33:${id}:1";
      environments = {
        MODE = "standalone";
      };
    };
  };
}

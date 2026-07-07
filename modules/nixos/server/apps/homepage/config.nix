{ lib, config, ... }:
let
  cfg = config.custom.apps.homepage;
in
{
  config = lib.mkIf cfg.enable {
    sops.templates."homepage/docker.yaml" = {
      restartUnits = [ "homepage" ];
      owner = cfg.user.name;
      content = ''
        docker:
          host: homepage-proxy
          port: 2375
      '';
    };
  };
}

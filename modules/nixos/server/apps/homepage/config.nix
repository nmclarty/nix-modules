{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkSecrets;
  cfg = config.custom.apps.homepage;
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "homepage/unifi/href"
      ] config.custom.base.secrets.podman;

      templates = {
        "homepage/bookmarks.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = "";
        };

        "homepage/docker.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = ''
            docker:
              host: homepage-proxy
              port: 2375
          '';
        };

        "homepage/services.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = ''
            - Management:
              - Unifi:
                  icon: unifi-controller.png
                  href: ${config.sops.placeholder."homepage/unifi/href"}
          '';
        };

        "homepage/settings.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = "";
        };

        "homepage/widgets.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = ''
            - resources:
                cpu: true
                memory: true
                disk: /

            - search:
                provider: [ duckduckgo, google ]
                focus: true
                showSearchSuggestions: true
                target: _blank
          '';
        };
      };
    };
  };
}

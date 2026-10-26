{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkSecrets;
  cfg = config.custom.apps.homepage;

  listed = lib.filterAttrs (_: r: r.homepage != null) config.custom.apps.traefik.routes;
  entries = lib.mapAttrsToList (_: r: {
    ${r.homepage.group} = [
      {
        ${r.homepage.name} = {
          inherit (r.homepage) icon;
          href = "https://${r.host}";
        };
      }
    ];
  }) listed;
  extra = {
    Management = [
      {
        Unifi = {
          icon = "unifi-controller.png";
          href = config.sops.placeholder."homepage/unifi/href";
        };
      }
    ];
  };
  # yaml is a superset of json, so the grouped entries are written out as json
  services = lib.mapAttrsToList (group: items: { ${group} = items; }) (
    lib.zipAttrsWith (_: lib.concatLists) (entries ++ [ extra ])
  );
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

        "homepage/services.yaml" = {
          restartUnits = [ "homepage.service" ];
          owner = cfg.user.name;
          content = builtins.toJSON services;
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

{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkSecrets;
  cfg = config.custom.apps.grafana;
  inherit (config.custom.apps.settings) domain;
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "grafana/oauth/client_id"
        "grafana/oauth/client_secret"
      ] config.custom.base.secrets.podman;

      templates."grafana/grafana.ini" = {
        restartUnits = [ "grafana.service" ];
        owner = cfg.user.name;
        content = ''
          [server]
          root_url = https://grafana.${domain}

          [log]
          level = warn

          [analytics]
          reporting_enabled = false
          check_for_updates = false
          check_for_plugin_updates = false

          [auth]
          # only allow sso logins through pocket id
          disable_login_form = true

          [auth.generic_oauth]
          enabled = true
          auto_login = true
          name = Pocket ID
          client_id = ${config.sops.placeholder."grafana/oauth/client_id"}
          client_secret = ${config.sops.placeholder."grafana/oauth/client_secret"}
          auth_url = https://pocket.${domain}/authorize
          token_url = https://pocket.${domain}/api/oidc/token
          api_url = https://pocket.${domain}/api/oidc/userinfo
          scopes = openid email profile groups
          use_pkce = true
          # members of the pocket id "admin" group get full access, everyone else can only view
          role_attribute_path = contains(groups[*], 'admin') && 'GrafanaAdmin' || 'Viewer'
          allow_assign_grafana_admin = true
        '';
      };
    };
  };
}

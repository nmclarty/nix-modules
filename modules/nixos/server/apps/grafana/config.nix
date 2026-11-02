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

      templates = {
        "grafana/grafana.ini" = {
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

            [security]
            # otherwise an admin/admin user is created
            disable_initial_admin_creation = true

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
            role_attribute_path = contains(groups[*], 'admin') && 'GrafanaAdmin' || 'Viewer'
            allow_assign_grafana_admin = true
          '';
        };

        "grafana/datasources.yaml" = {
          restartUnits = [ "grafana.service" ];
          owner = cfg.user.name;
          content = builtins.toJSON {
            apiVersion = 1;
            datasources = [
              {
                name = "Loki";
                type = "loki";
                url = "http://grafana-loki:3100";
                isDefault = true;
                # drilldown-limits skips loki's default tenant injection
                jsonData.httpHeaderName1 = "X-Scope-OrgID";
                secureJsonData.httpHeaderValue1 = "fake";
              }
              {
                name = "Prometheus";
                type = "prometheus";
                url = "http://grafana-prometheus:9090";
              }
            ];
          };
        };

        "grafana/loki.yaml" = {
          restartUnits = [ "grafana-loki.service" ];
          owner = cfg.user.name;
          content = ''
            auth_enabled: false

            server:
              http_listen_port: 3100
              log_level: warn

            common:
              instance_addr: 127.0.0.1
              path_prefix: /loki
              storage:
                filesystem:
                  chunks_directory: /loki/chunks
                  rules_directory: /loki/rules
              replication_factor: 1
              ring:
                kvstore:
                  store: inmemory

            schema_config:
              configs:
                - from: 2020-10-24
                  store: tsdb
                  object_store: filesystem
                  schema: v13
                  index:
                    prefix: index_
                    period: 24h

            compactor:
              retention_enabled: true
              delete_request_store: filesystem
            limits_config:
              retention_period: 30d

            # needed by grafana's logs drilldown
            pattern_ingester:
              enabled: true

            analytics:
              reporting_enabled: false
          '';
        };
      };
    };
  };
}

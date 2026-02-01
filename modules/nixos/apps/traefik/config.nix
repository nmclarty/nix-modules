{ lib, customLib, config, ... }:
let
  inherit (customLib) mkSecrets;
  cfg = config.custom.apps.traefik;
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "traefik/porkbun/api_key"
        "traefik/porkbun/secret_key"
      ]
        config.custom.base.secrets.podman;

      templates = {
        "traefik/traefik.yaml" = {
          restartUnits = [ "traefik.service" ];
          owner = cfg.user.name;
          content = ''
            global:
              sendAnonymousUsage: true
            log:
              level: INFO
            ping:
              entryPoint: http
            accessLog:
              filePath: /data/logs/access.log

            entryPoints:
              http:
                address: :80
                http:
                  redirections:
                    entryPoint:
                      to: https
                      scheme: https
              https:
                address: :443
                asDefault: true
                http:
                  middlewares:
                    - security@file
                  tls:
                    certResolver: porkbun
                    domains:
                      - main: "${config.custom.apps.settings.domain}"
                        sans:
                          - "*.${config.custom.apps.settings.domain}"
                # fix for immich timeouts
                transport:
                  respondingTimeouts:
                    readTimeout: "0s"

            providers:
              file:
                filename: /etc/traefik/dynamic.yaml
              docker:
                endpoint: "tcp://socket-proxy:2375"
                exposedByDefault: false
                network: "exposed"
                allowEmptyServices: true
                defaultRule: "Host(`{{ normalize .ContainerName }}.${config.custom.apps.settings.domain}`)"

            api:
              dashboard: true
              disabledashboardad: true

            certificatesResolvers:
              porkbun:
                acme:
                  storage: /data/acme.json
                  dnsChallenge:
                    provider: porkbun
          '';
        };
        "traefik/dynamic.yaml" = {
          restartUnits = [ "traefik.service" ];
          owner = cfg.user.name;
          content = ''
            http:
              middlewares:
                security:
                  headers:
                    contentTypeNosniff: true
                    frameDeny: true
                    stsSeconds: 63072000
                    stsIncludeSubdomains: true
                    referrerPolicy: "strict-origin-when-cross-origin"
                    customResponseHeaders:
                      server: ""
                      x-powered-by: ""
          '';
        };

        "ddns-updater/config.json" = {
          restartUnits = [ "ddns-updater.service" ];
          owner = cfg.user.name;
          content =
            let
              # Well, I don't know why, but the client seems break with multple domains in that field,
              # even though it says it should support that. Working around this by templating json.
              settings = map
                (k: {
                  inherit (k) domain ip_version;
                  provider = "porkbun";
                  api_key = config.sops.placeholder."traefik/porkbun/api_key";
                  secret_api_key = config.sops.placeholder."traefik/porkbun/secret_key";
                }) [
                { domain = "*.${config.custom.apps.settings.domain}"; ip_version = "ipv4"; }
                { domain = "${config.custom.apps.settings.domain}"; ip_version = "ipv4"; }
              ];
            in
            builtins.toJSON { inherit settings; }; # expects settings to be a key
        };
      };
    };
  };
}

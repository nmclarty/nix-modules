{ lib, customLib, config, ... }:
let
  inherit (customLib) mkSecrets;
  cfg = config.custom.apps.seafile;
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "seafile/secret_key"
        "seafile/oauth/client_id"
        "seafile/oauth/client_secret"
      ]
        config.custom.base.secrets.podman;

      templates = {
        "seafile/seafile.conf" = {
          restartUnits = [ "seafile.service" ];
          owner = cfg.user.name;
          content = ''
            [quota]
            default = 250

            [history]
            keep_days = 30

            [fileserver]
            port = 8082
            use_go_fileserver = true
          '';
        };

        "seafile/seahub_settings.py" = {
          restartUnits = [ "seafile.service" ];
          owner = cfg.user.name;
          content = ''
            # initial
            SECRET_KEY = "${config.sops.placeholder."seafile/secret_key"}"
            TIME_ZONE = "Etc/UTC"

            # security
            ALLOWED_HOSTS = [ "seafile.${config.custom.apps.settings.domain}", "127.0.0.1" ]
            CSRF_COOKIE_SECURE = True
            SESSION_COOKIE_SECURE = True

            # general
            ENABLE_TWO_FACTOR_AUTH = True
            ENABLE_WIKI = False
            SITE_TITLE = "Seafile"
            LOGOUT_REDIRECT_URL = "https://seafile.${config.custom.apps.settings.domain}/accounts/login/"

            # library
            ENCRYPTED_LIBRARY_VERSION = 4
            ENCRYPTED_LIBRARY_PWD_HASH_ALGO = "argon2id"
            ENCRYPTED_LIBRARY_PWD_HASH_PARAMS = "2,102400,8"
            ENABLE_REPO_SNAPSHOT_LABEL = True
            ENABLE_REPO_HISTORY_SETTING = False

            # oidc for pocket id integration
            ENABLE_OAUTH = True
            CLIENT_SSO_VIA_LOCAL_BROWSER = True
            OAUTH_CLIENT_ID = "${config.sops.placeholder."seafile/oauth/client_id"}"
            OAUTH_CLIENT_SECRET = "${config.sops.placeholder."seafile/oauth/client_secret"}"
            OAUTH_REDIRECT_URL = "https://seafile.${config.custom.apps.settings.domain}/oauth/callback/"
            OAUTH_PROVIDER = "pocket-id"
            OAUTH_AUTHORIZATION_URL = "https://pocket.${config.custom.apps.settings.domain}/authorize"
            OAUTH_TOKEN_URL = "https://pocket.${config.custom.apps.settings.domain}/api/oidc/token"
            OAUTH_USER_INFO_URL = "https://pocket.${config.custom.apps.settings.domain}/api/oidc/userinfo"
            OAUTH_SCOPE = [ "openid", "email", "profile" ]
            OAUTH_ATTRIBUTE_MAP = {
                "sub": (True, "uid"),
                "name": (False, "name"),
                "email": (False, "contact_email")
            }
          '';
        };

        "seafile/seafevents.conf" = {
          restartUnits = [ "seafile.service" ];
          owner = cfg.user.name;
          content = ''
            [STATISTICS]
            enabled=true

            [SEAHUB EMAIL]
            enabled = true
            interval = 30m

            [FILE HISTORY]
            enabled = true
            suffix = md,txt,doc,docx,xls,xlsx,ppt,pptx,sdoc
          '';
        };

        "seafile/seafdav.conf" = {
          restartUnits = [ "seafile.service" ];
          owner = cfg.user.name;
          content = ''
            [WEBDAV]
            enabled = false
            port = 8080
            share_name = /seafdav
          '';
        };

        "seafile/gunicorn.conf.py" = {
          restartUnits = [ "seafile.service" ];
          owner = cfg.user.name;
          content = ''
            import os

            daemon = True
            workers = 5

            # default localhost:8000
            bind = "127.0.0.1:8000"

            # Pid
            pids_dir = '/opt/seafile/pids'
            pidfile = os.path.join(pids_dir, 'seahub.pid')

            # for file upload, we need a longer timeout value (default is only 30s, too short)
            timeout = 1200

            limit_request_line = 8190

            # for forwarder headers
            forwarder_headers = 'SCRIPT_NAME,PATH_INFO,REMOTE_USER'
          '';
        };
      };
    };
  };
}

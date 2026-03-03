{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (customLib) mkSecrets;
  cfg = config.custom.apps.forgejo;
in
{
  config = mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "forgejo/lfs_jwt_secret"
        "forgejo/jwt_secret"
        "forgejo/secret_key"
        "forgejo/internal_token"
        "forgejo/mariadb/password"
      ] config.custom.base.secrets.podman;

      templates."forgejo/app.ini" = {
        restartUnits = [ "forgejo.service" ];
        owner = cfg.user.name;
        content = ''
          APP_NAME = Forgejo
          RUN_USER = forgejo
          RUN_MODE = prod
          WORK_PATH = /var/lib/gitea

          [repository]
          ROOT = /var/lib/gitea/git/repositories

          [repository.local]
          LOCAL_COPY_PATH = /tmp/gitea/local-repo

          [repository.upload]
          TEMP_PATH = /tmp/gitea/uploads

          [server]
          APP_DATA_PATH = /var/lib/gitea
          SSH_DOMAIN = forgejo.${config.custom.apps.settings.domain}
          HTTP_PORT = 3000
          ROOT_URL = https://forgejo.${config.custom.apps.settings.domain}
          DISABLE_SSH = true
          ; In rootless gitea container only internal ssh server is supported
          START_SSH_SERVER = true
          SSH_PORT = 2222
          SSH_LISTEN_PORT = 2222
          BUILTIN_SSH_SERVER_USER = git
          LFS_START_SERVER = true
          DOMAIN = forgejo.${config.custom.apps.settings.domain}
          LFS_JWT_SECRET = ${config.sops.placeholder."forgejo/lfs_jwt_secret"}
          OFFLINE_MODE = true

          [database]
          PATH = /var/lib/gitea/data/gitea.db
          DB_TYPE = mysql
          HOST = forgejo-mariadb:3306
          NAME = forgejo
          USER = forgejo
          PASSWD = ${config.sops.placeholder."forgejo/mariadb/password"}
          SCHEMA =
          SSL_MODE = disable
          LOG_SQL = false

          [session]
          PROVIDER_CONFIG = /var/lib/gitea/data/sessions
          PROVIDER = file

          [picture]
          AVATAR_UPLOAD_PATH = /var/lib/gitea/data/avatars
          REPOSITORY_AVATAR_UPLOAD_PATH = /var/lib/gitea/data/repo-avatars

          [attachment]
          PATH = /var/lib/gitea/data/attachments

          [log]
          ROOT_PATH = /var/lib/gitea/data/log
          MODE = console
          LEVEL = info

          [security]
          INSTALL_LOCK = true
          SECRET_KEY = ${config.sops.placeholder."forgejo/secret_key"}
          REVERSE_PROXY_LIMIT = 1
          REVERSE_PROXY_TRUSTED_PROXIES = *
          INTERNAL_TOKEN = ${config.sops.placeholder."forgejo/internal_token"}
          PASSWORD_HASH_ALGO = pbkdf2_hi

          [service]
          DISABLE_REGISTRATION = true
          REQUIRE_SIGNIN_VIEW = false
          DEFAULT_KEEP_EMAIL_PRIVATE = true
          REGISTER_EMAIL_CONFIRM = false
          ENABLE_NOTIFY_MAIL = false
          ALLOW_ONLY_EXTERNAL_REGISTRATION = false
          ENABLE_CAPTCHA = false
          DEFAULT_ALLOW_CREATE_ORGANIZATION = true
          DEFAULT_ENABLE_TIMETRACKING = true
          NO_REPLY_ADDRESS = noreply.forgejo.${config.custom.apps.settings.domain}

          [lfs]
          PATH = /var/lib/gitea/git/lfs

          [openid]
          ENABLE_OPENID_SIGNUP = false
          ENABLE_OPENID_SIGNIN = false

          [mailer]
          ENABLED = false

          [cron.update_checker]
          ENABLED = true

          [repository.pull-request]
          DEFAULT_MERGE_STYLE = merge

          [repository.signing]
          DEFAULT_TRUST_MODEL = committer

          [oauth2]
          JWT_SECRET = ${config.sops.placeholder."forgejo/jwt_secret"}
        '';
      };
    };
  };
}

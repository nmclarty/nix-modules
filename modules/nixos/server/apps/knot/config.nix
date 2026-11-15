{ lib, config, ... }:
let
  cfg = config.custom.apps.knot;
in
{
  config = lib.mkIf cfg.enable {
    sops.templates."knot/config.toml" = {
      restartUnits = [ "knot.service" ];
      owner = cfg.user.name;
      content = ''
        [server]
        hostname = "${config.custom.apps.traefik.routes.knot.host}"
        admins = ${builtins.toJSON cfg.admins}
        listen_addr = "[::]:5555"
        ssh_listen_addr = "[::]:2222"
        ssh_host_key_file = "/data/ssh_host_key"

        [repo]
        scan_path = "/data/repos"

        [secrets]
        sealed_key_file = "/data/sealed-keys"
        master_key_env = "KNOT_MASTER_KEY"

        [atproto]
        plc_directory = "https://plc.directory"

        [lfs]
        store_path = "/data/lfs"

        [contact]
        email = "${cfg.email}"
      '';
    };
  };
}

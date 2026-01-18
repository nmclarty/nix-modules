{ lib, config, ... }:
let
  cfg = config.apps.garage;
in
{
  config = lib.mkIf cfg.enable {
    sops.templates."garage/garage.toml" = {
      restartUnits = [ "garage.service" ];
      owner = cfg.user.name;
      content = ''
        metadata_dir = "/var/lib/garage/meta"
        data_dir = "/var/lib/garage/data"
        db_engine = "sqlite"

        replication_factor = 1
        compression_level = "none"
        block_size = "128MiB"

        rpc_bind_addr = "[::]:3901"

        [s3_api]
        s3_region = "wilds"
        api_bind_addr = "[::]:3900"
      '';
    };
  };
}

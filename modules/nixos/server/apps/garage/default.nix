{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.garage;
  id = toString cfg.user.id;
in
{
  imports = [ ./config.nix ];
  options.custom.apps.garage = mkOptions {
    id = 2001;
    name = "garage";
    tags.default = "v2.1.0";
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/garage/meta - ${id} ${id}"
      "d /cold/garage/data - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.garage.containerConfig = {
      image = "docker.io/dxflrs/garage:${cfg.tags.default}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      networks = [ "host" ];
      environments = {
        GARAGE_RPC_SECRET_FILE = "/run/secrets/garage__rpc_secret";
      };
      secrets = [ "garage__rpc_secret,uid=${id},gid=${id},mode=0400" ];
      volumes = [
        "${config.sops.templates."garage/garage.toml".path}:/etc/garage.toml:ro"
        "/srv/garage/meta:/var/lib/garage/meta"
        "/cold/garage/data:/var/lib/garage/data"
      ];
    };
  };
}

{
  lib,
  pkgs,
  customLib,
  tangled,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.knot;
  id = toString cfg.user.id;

  image = pkgs.dockerTools.buildLayeredImage {
    name = "knot";
    # busybox is only there for the healthcheck's shell and wget
    contents = [
      tangled.packages.${pkgs.stdenv.hostPlatform.system}.knot-rs
      pkgs.cacert
      pkgs.busybox
    ];
    config = {
      Entrypoint = [ "/bin/knot-server" ];
      Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
    };
  };
in
{
  imports = [ ./config.nix ];
  options.custom.apps.knot =
    mkOptions {
      id = 2014;
      name = "knot";
      tags = { };
    }
    // {
      admins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "The DIDs that administer the knot.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "The contact email the knot publishes.";
      };
    };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/knot/data 0750 ${id} ${id}"
      "d /srv/knot/data/repos 0750 ${id} ${id}"
      "d /srv/knot/data/lfs 0750 ${id} ${id}"
    ];

    custom.apps.traefik.routes.knot = {
      container = "knot";
      port = 5555;
      public = true;
    };

    virtualisation.quadlet.containers.knot.containerConfig = {
      image = "docker-archive:${image}";
      # there's no registry to check, so updates arrive with flake.lock instead
      autoUpdate = null;
      user = "${id}:${id}";
      exec = [
        "--config"
        "/etc/knot/config.toml"
      ];
      secrets = [ "knot__master_key,type=env,target=KNOT_MASTER_KEY" ];
      volumes = [
        "${config.sops.templates."knot/config.toml".path}:/etc/knot/config.toml:ro"
        "/srv/knot/data:/data"
      ];
      publishPorts = [ "22:2222" ];
      healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:5555/xrpc/_health";
    };
  };
}

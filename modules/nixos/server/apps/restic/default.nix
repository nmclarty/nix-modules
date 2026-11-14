{
  lib,
  pkgs,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.restic;
  id = toString cfg.user.id;
  data = "/cold/restic";

  image = pkgs.dockerTools.buildLayeredImage {
    name = "rest-server";
    # busybox is only there for the healthcheck's shell and wget
    contents = with pkgs; [
      restic-rest-server
      busybox
    ];
    config.Entrypoint = [ "/bin/rest-server" ];
  };
in
{
  options.custom.apps.restic = mkOptions {
    id = 2013;
    name = "restic";
    tags = { };
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [ "d ${data} 0700 ${id} ${id}" ];

    services.tailscale.serve = {
      enable = true;
      services.restic.endpoints."tcp:8000" = "tcp://127.0.0.1:8000";
    };
    custom.server.alloy.scrapes.restic.address = "127.0.0.1:8000";

    virtualisation.quadlet.containers.restic = {
      unitConfig.AssertPathIsMountPoint = data;
      containerConfig = {
        image = "docker-archive:${image}";
        # there's no registry to check, so updates arrive with flake.lock instead
        autoUpdate = null;
        user = "${id}:${id}";
        # each htpasswd user only reaches the repo at /<user>/, and can't delete or overwrite
        # anything but its locks, so pruning has to happen against the host directory directly;
        # metrics are unauthenticated since the healthcheck and alloy can't log in
        exec = [
          "--path=/data"
          "--htpasswd-file=/run/secrets/restic__htpasswd"
          "--append-only"
          "--private-repos"
          "--prometheus"
          "--prometheus-no-auth"
        ];
        secrets = [ "restic__htpasswd,uid=${id},gid=${id},mode=0400" ];
        volumes = [ "${data}:/data" ];
        publishPorts = [ "127.0.0.1:8000:8000" ];
        healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:8000/metrics";
      };
    };
  };
}

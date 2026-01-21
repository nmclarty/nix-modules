{ inputs, lib, config, ... }:
let
  inherit (inputs.helper-tools.lib) mkContainerUser;
  cfg = config.apps.beszel;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/beszel - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.beszel.containerConfig = {
      image = "docker.io/henrygd/beszel:${cfg.tag}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      volumes = [ "/srv/beszel:/beszel_data" ];
      networks = [ "exposed.network" ];
      labels = { "traefik.enable" = "true"; };
    };
  };
}

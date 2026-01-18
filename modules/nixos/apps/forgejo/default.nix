{ inputs, lib, config, ... }:
let
  inherit (inputs.nix-helpers.lib) mkContainerUser;
  cfg = config.apps.forgejo;
  id = toString cfg.user.id;
in
{
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/forgejo/data - ${id} ${id}"
    ];

    virtualisation.quadlet.containers.forgejo.containerConfig = {
      image = "codeberg.org/forgejo/forgejo:${cfg.tag}";
      autoUpdate = "registry";
      user = "${id}:${id}";
      volumes = [ "/srv/forgejo/data:/var/lib/gitea" ];
      publishPorts = [
        "3000:3000"
        "22:2222"
      ];
      healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:3000";
      healthStartupCmd = "sleep 10";
      healthOnFailure = "kill";
    };
  };
}

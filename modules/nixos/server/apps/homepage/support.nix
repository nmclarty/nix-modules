{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.apps.homepage;
in
{
  config = mkIf cfg.enable {
    virtualisation.quadlet.containers.homepage-proxy.containerConfig = {
      image = "lscr.io/linuxserver/socket-proxy:${cfg.tags.socket-proxy}";
      autoUpdate = "registry";
      readOnly = true;
      tmpfses = [ "/tmp" ];
      environments = {
        CONTAINERS = "1";
        LOG_LEVEL = "notice";
      };
      volumes = [ "/var/run/podman/podman.sock:/var/run/docker.sock:ro" ];
      networks = [ "homepage" ];
      healthCmd = "wget -O - -q -T 5 http://127.0.0.1:2375/_ping";
      healthStartupCmd = "sleep 10";
      healthOnFailure = "kill";
    };
  };
}

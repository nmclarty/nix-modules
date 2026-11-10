{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.custom.base.tailscale;
in
{
  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    systemd.services.tailscaled = {
      # stop ssh connection from dropping while rebuilding
      restartIfChanged = false;
      serviceConfig.LogLevelMax = "notice";
    };
    # serve fails with "unexpected state: NoState" if tailscaled hasn't finished starting
    systemd.services.tailscale-serve = mkIf config.services.tailscale.serve.enable {
      wants = [ "tailscale-online.target" ];
      after = [ "tailscale-online.target" ];
    };
  };
}

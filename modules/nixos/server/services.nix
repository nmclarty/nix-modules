{ lib, config, ... }:
{
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
    };
    # clean up lingering apps (gdu)
    logind.settings.Login.KillUserProcesses = true;
  };

  # networkd is needed for tailscale dns
  networking.useNetworkd = true;
  systemd.services.tailscaled = {
    # stop ssh connection from dropping while rebuilding
    restartIfChanged = false;
    serviceConfig.LogLevelMax = "notice";
  };
  # serve fails with "unexpected state: NoState" if tailscaled hasn't finished starting
  systemd.services.tailscale-serve = lib.mkIf config.services.tailscale.serve.enable {
    wants = [ "tailscale-online.target" ];
    after = [ "tailscale-online.target" ];
  };
}

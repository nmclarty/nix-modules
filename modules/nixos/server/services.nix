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
}

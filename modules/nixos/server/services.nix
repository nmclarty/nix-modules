{
  # clean up lingering apps (gdu)
  services.logind.settings.Login.KillUserProcesses = true;

  # networkd is needed for tailscale dns
  networking.useNetworkd = true;
}

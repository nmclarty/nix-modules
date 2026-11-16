{
  # clean up lingering apps (gdu)
  services.logind.settings.Login.KillUserProcesses = true;

  # networkd is needed for tailscale dns
  networking.useNetworkd = true;

  # servers run no openssh, so this is the only way in
  services.tailscale = {
    extraSetFlags = [ "--ssh" ];
    # a one-off key placed at install; only read while the node is logged out
    authKeyFile = "/var/lib/tailscale/auth-key";
  };
}

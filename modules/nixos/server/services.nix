{ flake, config, lib, ... }:
let
  beszelServer = lib.findFirst
    (name: with flake.nixosConfigurations.${name}.config; custom ? apps && custom.apps.beszel.enable)
    (throw "No Beszel server found")
    (builtins.attrNames flake.nixosConfigurations);
in
{
  # tailscale (and ssh)
  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "server";
    };
    # clean up lingering apps (gdu)
    logind.settings.Login.KillUserProcesses = true;
    iperf3 = {
      enable = true;
      openFirewall = true;
    };
    beszel.agent = {
      enable = true;
      environmentFile = config.sops.templates."beszel/agent".path;
    };
  };

  # networkd is needed for tailscale dns
  networking.useNetworkd = true;
  systemd.services.tailscaled = {
    # stop ssh connection from dropping while rebuilding
    restartIfChanged = false;
    serviceConfig.LogLevelMax = "notice";
  };

  sops = {
    secrets = {
      "beszel/key" = { };
      "beszel/token" = { };
    };
    templates."beszel/agent" = {
      restartUnits = [ "beszel-agent.service" ];
      content = ''
        LISTEN=45876
        KEY="${config.sops.placeholder."beszel/key"}"
        TOKEN="${config.sops.placeholder."beszel/token"}"
        HUB_URL="http://${beszelServer}:8090"
      '';
    };
  };
}

{ lib, flake, config, pkgs, ... }:
let
  beszelServer = lib.findFirst
    (name: with flake.nixosConfigurations.${name}.config; custom ? apps && custom.apps.beszel.enable)
    (throw "No Beszel server found")
    (builtins.attrNames flake.nixosConfigurations);
in
{
  systemd.services.beszel-agent = {
    enable = true;
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    path = with pkgs; [ smartmontools ] ++ lib.optionals
      (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ intel-gpu-tools ];
    serviceConfig = {
      ExecStart = "${pkgs.beszel}/bin/beszel-agent";
      EnvironmentFile = config.sops.templates."beszel/agent".path;
      Restart = "on-failure";
      RestartSec = 5;
      StateDirectory = "beszel-agent";

      # security (as per upstream)
      KeyringMode = "private";
      LockPersonality = true;
      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectHome = "read-only";
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictSUIDSGID = true;
    };
  };
  sops = {
    secrets = {
      "beszel/key" = { };
      "beszel/token" = { };
    };
    templates."beszel/agent" = {
      restartUnits = [ "beszel-agent.service" ];
      content = ''
        # hub
        LISTEN=45876
        KEY="${config.sops.placeholder."beszel/key"}"
        TOKEN="${config.sops.placeholder."beszel/token"}"
        HUB_URL="http://${beszelServer}:8090"

        # hardware
        DOCKER_HOST=unix:///run/podman/podman.sock
      '';
    };
  };
}

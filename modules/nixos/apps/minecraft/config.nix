{ lib, config, ... }:
let
  cfg = config.apps.minecraft;
in
{
  config = lib.mkIf cfg.enable {
    sops.templates."minecraft/velocity/velocity.toml" = {
      restartUnits = [ "velocity.service" ];
      owner = cfg.user.name;
      content = ''
        config-version = "2.7"
        bind = "0.0.0.0:25565"
        motd = "<green><b>the earth says hello!</b></green>\nsurvival | creative"
        show-max-players = 20
        online-mode = true
        force-key-authentication = true
        prevent-client-proxy-connections = false
        player-info-forwarding-mode = "modern"
        forwarding-secret-file = "/run/secrets/minecraft__velocity__forwarding_secret"
        announce-forge = false
        kick-existing-players = false
        ping-passthrough = "disabled"
        enable-player-address-logging = true

        [servers]
        survival = "minecraft-survival:25565"
        creative = "minecraft-creative:25565"
        try = [ "survival", "creative" ]

        [forced-hosts]
        "survival.obsidiantech.ca" = [ "survival" ]
        "creative.obsidiantech.ca" = [ "creative" ]

        [advanced]
        compression-threshold = 256
        compression-level = -1
        login-ratelimit = 3000
        connection-timeout = 5000
        read-timeout = 30000
        haproxy-protocol = false
        tcp-fast-open = false
        bungee-plugin-message-channel = true
        show-ping-requests = false
        failover-on-unexpected-server-disconnect = true
        announce-proxy-commands = true
        log-command-executions = false
        log-player-connections = true
        accepts-transfers = false

        [query]
        enabled = false
        port = 25577
        map = "Velocity"
        show-plugins = false
      '';
    };
  };
}

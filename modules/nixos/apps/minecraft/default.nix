{ inputs, lib, config, ... }:
let
  inherit (inputs.nix-helpers.lib) mkContainerUser;
  cfg = config.apps.minecraft;
  id = toString cfg.user.id;
in
{
  imports = [ ./config.nix ./support.nix ];
  config = lib.mkIf cfg.enable {
    users = mkContainerUser { inherit (cfg.user) name id; };

    systemd.tmpfiles.rules = [
      "d /srv/minecraft/velocity - ${id} ${id}"
      "d /srv/minecraft/survival - ${id} ${id}"
      "d /srv/minecraft/creative - ${id} ${id}"
      "d /srv/minecraft/biomes - ${id} ${id}"
      "d /srv/minecraft/mariadb - ${id} ${id}"
    ];

    virtualisation.quadlet = {
      containers = {
        velocity = {
          autoStart = false;
          containerConfig = {
            image = "docker.io/itzg/mc-proxy:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              TYPE = "VELOCITY";
            };
            secrets = [ "minecraft__velocity__forwarding_secret,uid=${id},gid=${id},mode=0400" ];
            volumes = [
              "/srv/minecraft/velocity:/server"
              "${config.sops.templates."minecraft/velocity/velocity.toml".path}:/server/velocity.toml:ro"
            ];
            networks = [ "minecraft.network" ];
            publishPorts = [ "25565:25565" ];
          };
        };

        minecraft-survival = {
          autoStart = false;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              EULA = "TRUE";
              TYPE = "PAPER";
              VERSION = "1.21.4";
              MEMORY = "4G";
            };
            volumes = [ "/srv/minecraft/survival:/data" ];
            networks = [ "minecraft.network" ];
            healthCmd = "mc-health";
            healthStartupCmd = "sleep 30";
            healthOnFailure = "kill";
          };
        };

        minecraft-creative = {
          autoStart = false;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              EULA = "TRUE";
              TYPE = "PAPER";
              VERSION = "1.21.4";
              MEMORY = "4G";
            };
            volumes = [ "/srv/minecraft/creative:/data" ];
            networks = [ "minecraft.network" ];
            healthCmd = "mc-health";
            healthStartupCmd = "sleep 30";
            healthOnFailure = "kill";
          };
        };

        minecraft-biomes = {
          autoStart = false;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tag}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              EULA = "TRUE";
              TYPE = "FORGE";
              VERSION = "1.20.1";
              FORGE_VERSION = "47.4.9";
              INIT_MEMORY = "2G";
              MAX_MEMORY = "8G";
            };
            volumes = [ "/srv/minecraft/biomes:/data" ];
            networks = [ "minecraft.network" ];
            publishPorts = [ "25566:25565" ];
            healthCmd = "mc-health";
            healthStartupCmd = "sleep 30";
            healthOnFailure = "kill";
          };
        };

      };
      networks = { minecraft = { }; };
    };
  };
}

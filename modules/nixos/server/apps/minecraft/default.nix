{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  cfg = config.custom.apps.minecraft;
  id = toString cfg.user.id;
in
{
  imports = [
    ./support.nix
  ];
  options.custom.apps.minecraft = mkOptions {
    id = 2007;
    name = "minecraft";
    tags = {
      default = "stable";
      mariadb = "10.11";
    };
    autoStart = false;
  };

  config = lib.mkIf cfg.enable {
    users = mkUser { inherit (cfg.user) name id; };

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
          autoStart = cfg.autoStart;
          containerConfig = {
            image = "docker.io/itzg/mc-proxy:${cfg.tags.default}";
            autoUpdate = "registry";
            user = "${id}:${id}";
            environments = {
              TYPE = "VELOCITY";
              VELOCITY_VERSION = "4.1.0";
            };
            secrets = [ "minecraft__velocity__forwarding_secret,uid=${id},gid=${id},mode=0400" ];
            volumes = [ "/srv/minecraft/velocity:/server" ];
            networks = [ "minecraft.network" ];
            publishPorts = [ "25565:25565" ];
            healthCmd = "/usr/bin/health.sh";
            healthStartupCmd = "sleep 10";
            healthOnFailure = "kill";
          };
        };

        minecraft-survival = {
          autoStart = cfg.autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
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
          autoStart = cfg.autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
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
          autoStart = cfg.autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
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
      networks = {
        minecraft = { };
      };
    };
  };
}

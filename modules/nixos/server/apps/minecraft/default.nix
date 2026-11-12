{
  lib,
  customLib,
  config,
  ...
}:
let
  inherit (customLib.apps) mkOptions mkUser;
  inherit (config.virtualisation.quadlet) networks;
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
      "d /srv/minecraft/velocity 0750 ${id} ${id}"
      "d /srv/minecraft/survival 0750 ${id} ${id}"
      "d /srv/minecraft/creative 0750 ${id} ${id}"
      "d /srv/minecraft/biomes 0750 ${id} ${id}"
      "d /srv/minecraft/mariadb 0750 ${id} ${id}"
    ];

    virtualisation.quadlet = {
      containers = {
        velocity = {
          inherit (cfg) autoStart;
          containerConfig = {
            image = "docker.io/itzg/mc-proxy:${cfg.tags.default}";
            user = "${id}:${id}";
            environments.TYPE = "VELOCITY";
            volumes = [ "/srv/minecraft/velocity:/server" ];
            networks = [ networks.minecraft-support.ref ];
            publishPorts = [ "25565:25565" ];
            healthCmd = "/usr/bin/health.sh";
          };
        };

        minecraft-survival = {
          inherit (cfg) autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
            user = "${id}:${id}";
            environments = {
              EULA = "TRUE";
              TYPE = "PAPER";
              VERSION = "1.21.4";
              MEMORY = "4G";
            };
            volumes = [ "/srv/minecraft/survival:/data" ];
            networks = [ networks.minecraft-support.ref ];
            healthCmd = "mc-health";
          };
        };

        minecraft-creative = {
          inherit (cfg) autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
            user = "${id}:${id}";
            environments = {
              EULA = "TRUE";
              TYPE = "PAPER";
              VERSION = "1.21.4";
              MEMORY = "4G";
            };
            volumes = [ "/srv/minecraft/creative:/data" ];
            networks = [ networks.minecraft-support.ref ];
            healthCmd = "mc-health";
          };
        };

        minecraft-biomes = {
          inherit (cfg) autoStart;
          containerConfig = {
            image = "docker.io/itzg/minecraft-server:${cfg.tags.default}";
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
            networks = [ networks.minecraft-support.ref ];
            publishPorts = [ "25566:25565" ];
            healthCmd = "mc-health";
          };
        };

      };
      networks = {
        minecraft-support = { };
      };
    };
  };
}

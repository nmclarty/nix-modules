{ config, ... }:
let
  overworld = { key, name, sorting }: ''
    world: "/worlds/${key}/world"
    dimension: "minecraft:overworld"
    name: "${name} Overworld"
    sorting: ${toString sorting}
    sky-color: "#7dabff"
    void-color: "#000000"
    sky-light: 1
    ambient-light: 0.1
    remove-caves-below-y: 55
    cave-detection-ocean-floor: -5
    cave-detection-uses-block-light: false
    min-inhabited-time: 0
    render-mask: []
    render-edges: true
    edge-light-strength: 8
    enable-perspective-view: false
    enable-flat-view: true
    enable-free-flight-view: false
    enable-hires: false
    storage: "sql"
    ignore-missing-light-data: false
    marker-sets: {}
  '';

  nether = { key, name, sorting, isPaper ? true }: ''
    world: "/worlds/${key}/world${if isPaper then "_nether" else ""}"
    dimension: "minecraft:the_nether"
    name: "${name} Nether"
    sorting: ${toString sorting}
    sky-color: "#290000"
    void-color: "#150000"
    sky-light: 1
    ambient-light: 0.6
    remove-caves-below-y: -10000
    cave-detection-ocean-floor: -5
    cave-detection-uses-block-light: false
    min-inhabited-time: 0
    render-mask: [
      {
        # this removes everything at and between y 90 and 127 (the nethers ceiling)
        # structures above the bedrock-ceiling remain visible
        subtract: true
        min-y: 90
        max-y: 127
      }
    ]
    render-edges: true
    edge-light-strength: 8
    enable-perspective-view: false
    enable-flat-view: true
    enable-free-flight-view: false
    enable-hires: false
    storage: "sql"
    ignore-missing-light-data: false
    marker-sets: {}
  '';

  end = { key, name, sorting, isPaper ? true }: ''
    world: "/worlds/${key}/world${if isPaper then "_the_end" else ""}"
    dimension: "minecraft:the_end"
    name: "${name} End"
    sorting: ${toString sorting}
    sky-color: "#080010"
    void-color: "#080010"
    sky-light: 1
    ambient-light: 0.6
    remove-caves-below-y: -10000
    cave-detection-ocean-floor: -5
    cave-detection-uses-block-light: false
    min-inhabited-time: 0
    render-mask: []
    render-edges: true
    edge-light-strength: 8
    enable-perspective-view: false
    enable-flat-view: true
    enable-free-flight-view: false
    enable-hires: false
    storage: "sql"
    ignore-missing-light-data: false
    marker-sets: {}
  '';
in
{
  # all files must not be symlinks otherwise the container can't access them.
  environment.etc = {
    "config/bluemap/core.conf" = {
      mode = "0644";
      text = ''
        accept-download: true
        data: "data"
        render-thread-count: 8
        scan-for-mod-resources: true
        metrics: true
        log: {
          file: "data/logs/debug.log"
          append: false
        }
      '';
    };

    "config/bluemap/webapp.conf" = {
      mode = "0644";
      text = ''
        enabled: true
        webroot: "web"
        update-settings-file: true
        use-cookies: true
        default-to-flat-view: false
        min-zoom-distance: 5
        max-zoom-distance: 100000
        resolution-default: 1
        hires-slider-max: 500
        hires-slider-default: 100
        hires-slider-min: 0
        lowres-slider-max: 7000
        lowres-slider-default: 2000
        lowres-slider-min: 500
        scripts: []
        styles: []
      '';
    };

    "config/bluemap/webserver.conf" = {
      mode = "0644";
      text = ''
        enabled: true
        webroot: "web"
        port: 8100
        log: {
          file: "data/logs/webserver.log"
          append: false
          format: "%1$s \"%3$s %4$s %5$s\" %6$s %7$s"
        }
      '';
    };

    # survival world
    "config/bluemap/maps/survival_overworld.conf" = {
      mode = "0644";
      text = overworld {
        key = "survival";
        name = "Survival";
        sorting = 0;
      };
    };
    "config/bluemap/maps/survival_nether.conf" = {
      mode = "0644";
      text = nether {
        key = "survival";
        name = "Survival";
        sorting = 10;
      };
    };
    "config/bluemap/maps/survival_end.conf" = {
      mode = "0644";
      text = end {
        key = "survival";
        name = "Survival";
        sorting = 20;
      };
    };

    # creative world
    "config/bluemap/maps/creative_overworld.conf" = {
      mode = "0644";
      text = overworld {
        key = "creative";
        name = "Creative";
        sorting = 1;
      };
    };
    "config/bluemap/maps/creative_nether.conf" = {
      mode = "0644";
      text = nether {
        key = "creative";
        name = "Creative";
        sorting = 11;
      };
    };
    "config/bluemap/maps/creative_end.conf" = {
      mode = "0644";
      text = end {
        key = "creative";
        name = "Creative";
        sorting = 21;
      };
    };

    # biomes world
    "config/bluemap/maps/biomes_overworld.conf" = {
      mode = "0644";
      text = overworld {
        key = "biomes";
        name = "Biomes";
        sorting = 2;
      };
    };
    "config/bluemap/maps/biomes_nether.conf" = {
      mode = "0644";
      text = nether {
        key = "biomes";
        name = "Biomes";
        sorting = 12;
        isPaper = false;
      };
    };
    "config/bluemap/maps/biomes_end.conf" = {
      mode = "0644";
      text = end {
        key = "biomes";
        name = "Biomes";
        sorting = 22;
        isPaper = false;
      };
    };

    # these are just here so bluemap doesn't complain about missing files
    "config/bluemap/packs/empty.txt" = {
      mode = "0644";
      text = "";
    };
  };

  sops.secrets."minecraft/mariadb/password" = {
    sopsFile = config.custom.base.secrets.podman;
    key = "minecraft/mariadb/password";
  };
  sops.templates."minecraft/bluemap/sql.conf" = {
    restartUnits = [ "bluemap.service" ];
    owner = "minecraft";
    content = ''
      storage-type: sql
      connection-url: "jdbc:mysql://minecraft-mariadb:3306/minecraft?permitMysqlScheme"
      connection-properties: {
          user: "minecraft",
          password: "${config.sops.placeholder."minecraft/mariadb/password"}"
      }
      max-connections: -1
      driver-jar: "/app/mariadb-java-client.jar"
      driver-class: "org.mariadb.jdbc.Driver"
      compression: gzip
    '';
  };
  virtualisation.quadlet = {
    containers = {
      bluemap = {
        containerConfig = {
          image = "ghcr.io/bluemap-minecraft/bluemap:v5";
          autoUpdate = "registry";
          user = "2005:2005";
          exec = "-r -u -w";
          volumes = [
            # app folders
            "/etc/config/bluemap:/app/config:ro"
            "/srv/minecraft/bluemap/web:/app/web"
            "/srv/minecraft/bluemap/data:/app/data"
            "/srv/minecraft/bluemap/mariadb-java-client-3.4.1.jar:/app/mariadb-java-client.jar:ro"
            "${
              config.sops.templates."minecraft/bluemap/sql.conf".path
            }:/app/config/storages/sql.conf:ro"
            # worlds
            "/srv/minecraft/survival:/worlds/survival:ro"
            "/srv/minecraft/creative:/worlds/creative:ro"
            "/srv/minecraft/biomes:/worlds/biomes:ro"
          ];
          networks = [ "minecraft.network" "exposed.network" ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.services.bluemap.loadbalancer.server.port" = "8100";
          };
          healthCmd = "wget -O /dev/null -q -T 5 http://127.0.0.1:8100";
          healthStartupCmd = "sleep 10";
          healthOnFailure = "kill";
        };
        serviceConfig.AllowedCPUs = config.apps.settings.cpus;
        unitConfig = {
          Wants = [ "minecraft-mariadb.service" ];
          After = [ "minecraft-mariadb.service" ];
        };
      };
    };
  };
}

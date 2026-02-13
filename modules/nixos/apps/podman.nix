{ config, ... }: {
  services.podman-sops = {
    # only enabled if the host has a podman.yaml in its hosts/ dir;
    # services that depend on podman secrets will complain if the file is missing
    enable = builtins.pathExists config.custom.base.secrets.podman;
    settings.sopsFile = config.custom.base.secrets.podman;
  };

  systemd.services.podman.environment.LOGGING = "--log-level=warn";
  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings = {
        containers.tz = "local";
        engine.events_logger = "file";
      };
    };
    podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = [ "--all" ];
      };
    };
    quadlet = {
      enable = true;
      autoUpdate = {
        enable = true;
        calendar = "weekly";
      };
    };
  };
  # this is required for rootful user namespacing (i.e. userns = "auto"; )
  users.users.containers = {
    isSystemUser = true;
    autoSubUidGidRange = true;
    group = "containers";
  };
  users.groups.containers = { };
}

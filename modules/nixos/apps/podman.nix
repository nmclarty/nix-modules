{ config, ... }: {
  services.podman-sops = {
    enable = true;
    # this means that podman-sops expects to find the encrypted sops file
    # within the consuming flake, in a dir matching the current system hostname
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

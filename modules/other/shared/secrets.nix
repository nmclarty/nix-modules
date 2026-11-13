{
  lib,
  config,
  flake,
  ...
}:
let
  inherit (lib) mkOption types;
  basePath = "${flake}/secrets";
  systemPath = "${basePath}/${config.networking.hostName}";
in
{
  options.custom.base.secrets = {
    global = mkOption {
      type = types.str;
      default = "${basePath}/system.yaml";
    };
    system = mkOption {
      type = types.str;
      default = "${systemPath}/system.yaml";
    };
    podman = mkOption {
      type = types.str;
      default = "${systemPath}/podman.yaml";
    };
  };

  config.sops = {
    defaultSopsFile = config.custom.base.secrets.global;
    log = [ "secretChanges" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      # safe since it only contains public keys
      "ssh/known_hosts" = {
        mode = "0444";
      };
    };
  };
}

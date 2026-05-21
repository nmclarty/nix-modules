{
  lib,
  config,
  flake,
  ...
}:
let
  inherit (lib) mkOption types;
  basePath = "${flake}/hosts";
  systemPath = "${basePath}/${config.networking.hostName}";
in
{
  options.custom.base.secrets = {
    global = mkOption {
      type = types.str;
      default = "${basePath}/secrets.yaml";
    };
    system = mkOption {
      type = types.str;
      default = "${systemPath}/secrets.yaml";
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
      "known_hosts" = {
        mode = "0444";
      };
    };
  };
}

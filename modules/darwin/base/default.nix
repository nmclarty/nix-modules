{ inputs, ... }:
{ flake, lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = with inputs; [
    sops-nix.darwinModules.sops
    ./programs.nix
    ./secrets.nix
    ./system.nix
    ./users.nix
  ];
  options.custom.base.secrets =
    let
      basePath = "${flake}/hosts";
      systemPath = "${basePath}/${config.networking.hostName}";
    in
    {
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
}

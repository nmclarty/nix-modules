{ inputs, ... }:
{ flake, lib, config, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = with inputs; [
    sops-nix.nixosModules.sops
    lanzaboote.nixosModules.lanzaboote
    ./motd.nix
    ./programs.nix
    ./secrets.nix
    ./secure-boot.nix
    ./system.nix
    ./users.nix
  ];
  options.custom.base = {
    secure-boot.enable = mkEnableOption "If secure boot management should be enabled.";
    secrets =
      let
        basePath = "${flake}/.sops";
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
  };
}

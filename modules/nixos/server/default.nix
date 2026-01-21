{ inputs, ... }:
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = with inputs; [
    quadlet-nix.nixosModules.quadlet
    helper-tools.nixosModules.sops-podman
    ./services.nix
    ./podman.nix
    ./system.nix
    ./ups.nix
  ];
  options.custom.server = {
    settings.domain = mkOption {
      type = types.str;
      default = "example.com";
      description = "The domain name to use for servers.";
    };
    ups = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If ups monitoring should be enabled.";
      };
      type = mkOption {
        type = types.enum [ "client" "server" ];
        default = "client";
        description = "If this machine should be a client or server.";
      };
    };
  };
}

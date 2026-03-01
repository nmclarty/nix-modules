{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./services.nix
    ./system.nix
    ./ups.nix
    ./beszel.nix
  ];
  options.custom.server = {
    ups = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If ups monitoring should be enabled.";
      };
      mode = mkOption {
        type = types.enum [
          "client"
          "server"
        ];
        default = "client";
        description = "If this machine should be a client or server.";
      };
    };
  };
}

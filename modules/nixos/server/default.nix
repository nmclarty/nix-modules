{ inputs, ... }:
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  config._module.args.customLib = inputs.self.lib;
  imports = with inputs; [
    quadlet-nix.nixosModules.quadlet
    helper-tools.nixosModules.secret
    ./apps
    ./services.nix
    ./system.nix
    ./ups.nix
    ./beszel.nix
  ];
  options.custom.server = {
    beszel = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If beszel monitoring agent should be enabled.";
      };
    };
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

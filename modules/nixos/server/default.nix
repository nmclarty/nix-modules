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
    ./alloy.nix
  ];
  options.custom.server = {
    alloy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If alloy should be enabled to ship journald logs to loki and host metrics to prometheus.";
      };
      scrapes = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              address = mkOption {
                type = types.str;
                description = "The host:port to scrape.";
              };
              metricsPath = mkOption {
                type = types.str;
                default = "/metrics";
                description = "The path metrics are served on.";
              };
            };
          }
        );
        default = { };
        description = "Extra prometheus endpoints for alloy to scrape and push, keyed by job name.";
      };
    };
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
        default = false;
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

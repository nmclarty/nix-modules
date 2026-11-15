{ inputs, ... }:
{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = with inputs; [
    sops-nix.nixosModules.sops
    self.modules.other.shared
    ./devel.nix
    ./programs.nix
    ./system.nix
    ./tailscale.nix
    ./users.nix
  ];
  options.custom.base = {
    devel.enable = mkEnableOption "If development tools should be enabled";
    tailscale = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If tailscale should be enabled.";
      };
    };
  };
}

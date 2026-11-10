{ inputs, ... }:
{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = with inputs; [
    sops-nix.nixosModules.sops
    lanzaboote.nixosModules.lanzaboote
    self.modules.other.shared
    ./devel.nix
    ./programs.nix
    ./secure-boot.nix
    ./system.nix
    ./tailscale.nix
    ./users.nix
  ];
  options.custom.base = {
    devel.enable = mkEnableOption "If development tools should be enabled";
    secure-boot.enable = mkEnableOption "If secure boot management should be enabled.";
    tailscale = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "If tailscale should be enabled.";
      };
    };
  };
}

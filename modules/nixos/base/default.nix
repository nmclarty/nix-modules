{ inputs, ... }:
{ lib, ... }:
let
  inherit (lib) mkEnableOption;
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
    ./users.nix
  ];
  options.custom.base = {
    devel.enable = mkEnableOption "If development tools should be enabled";
    secure-boot.enable = mkEnableOption "If secure boot management should be enabled.";
  };
}

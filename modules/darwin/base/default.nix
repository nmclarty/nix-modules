{ inputs, ... }:
{ ... }:
{
  imports = with inputs; [
    sops-nix.darwinModules.sops
    self.modules.other.shared
    ./programs.nix
    ./system.nix
    ./users.nix
  ];
}

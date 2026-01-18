{ inputs, ... }:
{ ... }:
{
  imports = with inputs; [
    nix-helpers.homeModules.py-motd
    ./cli
    ./packages.nix
  ];
  home = {
    stateVersion = "25.05";
    file.".hushlogin".text = "";
  };
}

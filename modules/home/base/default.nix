{ inputs, ... }:
{ ... }:
{
  imports = with inputs; [
    helper-tools.homeModules.py-motd
    ./cli
    ./packages.nix
  ];
  home = {
    stateVersion = "25.05";
    file.".hushlogin".text = "";
  };
  xdg.enable = true;
}

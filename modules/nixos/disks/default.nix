{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    ./root.nix
    ./cold.nix
  ];
}

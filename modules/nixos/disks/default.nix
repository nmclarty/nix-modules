{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./root.nix
    ./cold.nix
  ];
}

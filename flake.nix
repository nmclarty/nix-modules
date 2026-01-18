{
  description = "Nix modules for reuse across systems";
  inputs = {
    # system
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # utilities
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
    # extras
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs:
    inputs.blueprint { inherit inputs; };
}

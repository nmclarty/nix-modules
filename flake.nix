{
  description = "Nix modules for reuse across systems";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # utilities
    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
    helper-tools.url = "github:nmclarty/helper-tools";
    helper-tools.inputs.nixpkgs.follows = "nixpkgs";
    # base
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    # disks
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # server
    quadlet-nix.url = "github:seiarotg/quadlet-nix";
  };
  outputs = inputs:
    inputs.blueprint { inherit inputs; };
}

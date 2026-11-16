{ pkgs, ... }:
let
  # statix only accepts a single target, but treefmt passes many files
  statix-fix = pkgs.writeShellApplication {
    name = "statix-fix";
    runtimeInputs = [ pkgs.statix ];
    text = ''
      for f in "$@"; do
        statix fix "$f"
        # some lints have no automatic fix
        statix check "$f"
      done
    '';
  };
in
pkgs.treefmt.withConfig {
  runtimeInputs = with pkgs; [
    nixfmt
    statix-fix
    deadnix
    actionlint
  ];
  settings = {
    on-unmatched = "info";
    formatter = {
      nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };
      deadnix = {
        command = "deadnix";
        options = [ "--edit" ];
        includes = [ "*.nix" ];
      };
      statix = {
        command = "statix-fix";
        includes = [ "*.nix" ];
      };
      actionlint = {
        command = "actionlint";
        includes = [ ".github/workflows/*.yaml" ];
      };
    };
  };
}

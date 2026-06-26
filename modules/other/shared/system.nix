{
  lib,
  flake,
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mapAttrs mapAttrsToList;
in
{
  system.configurationRevision = flake.shortRev or flake.dirtyShortRev or "unknown";
  nix = {
    channel.enable = false;
    registry = mapAttrs (_: flake: { inherit flake; }) inputs;
    nixPath = mapAttrsToList (n: _: "${n}=flake:${n}") inputs;
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
      # schedule in nixos/darwin system.nix
    };
    optimise = {
      automatic = true;
      # schedule in nixos/darwin system.nix
    };
    settings = {
      # allowed-users in nixos/darwin system.nix
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
    extraOptions = "!include ${config.sops.templates."nix/access-tokens".path}";
  };

  sops = {
    secrets = {
      "nix/github-token" = { };
    };
    templates = {
      "nix/access-tokens" = {
        owner = "nmclarty";
        content = ''
          access-tokens = github.com=${config.sops.placeholder."nix/github-token"}
        '';
      };
    };
  };
}

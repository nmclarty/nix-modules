{
  lib,
  flake,
  inputs,
  config,
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
      substituters = [ "https://cache.garnix.io" ];
      trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
      netrc-file = config.sops.templates."nix/garnix-netrc".path;
      narinfo-cache-positive-ttl = 3600;
    };
    extraOptions = "!include ${config.sops.templates."nix/github-token".path}";
  };

  sops = {
    secrets = {
      "github/token" = { };
      "garnix/token" = { };
    };
    templates = {
      "nix/github-token" = {
        owner = "nmclarty";
        content = ''
          access-tokens = github.com=${config.sops.placeholder."github/token"}
        '';
      };
      "nix/garnix-netrc" = {
        owner = "nmclarty";
        content = ''
          machine cache.garnix.io
            login nmclarty
            password ${config.sops.placeholder."garnix/token"}
        '';
      };
    };
  };
}

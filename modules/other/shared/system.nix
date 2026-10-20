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
      options = "--delete-older-than 30d";
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
      extra-substituters = [ "https://cache.nmclarty.dev" ];
      extra-trusted-public-keys = [ "cache.nmclarty.dev-1:SnTCyV6+AwlU3Dk9VByQ2X4GYghLpGmbVnFp5Br5wRk=" ];
      netrc-file = config.sops.templates."nix/netrc-file".path;
    };
    extraOptions = "!include ${config.sops.templates."nix/access-tokens".path}";
  };

  sops = {
    secrets = {
      "nix/github-token" = { };
      "nix/cache-password" = { };
    };
    templates = {
      "nix/access-tokens" = {
        owner = "nmclarty";
        content = ''
          access-tokens = github.com=${config.sops.placeholder."nix/github-token"}
        '';
      };
      "nix/netrc-file" = {
        owner = "nmclarty";
        content = ''
          machine cache.nmclarty.dev
            login nix
            password ${config.sops.placeholder."nix/cache-password"}
        '';
      };
    };
  };
}

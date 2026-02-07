{
  flake,
  lib,
  inputs,
  config,
  ...
}:
{
  system = {
    stateVersion = 6;
    configurationRevision = flake.shortRev or flake.dirtyShortRev or "unknown";
  };

  nix = {
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) inputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") inputs;
    gc = {
      automatic = true;
      interval = [
        {
          Hour = 0;
          Minute = 0;
          Weekday = 1;
        }
      ]; # weekly
      options = "--delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      interval = [
        {
          Hour = 1;
          Minute = 0;
        }
      ]; # daily
    };
    settings = {
      allowed-users = [ "@admin" ];
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

  security.pam.services.sudo_local.touchIdAuth = true;
}

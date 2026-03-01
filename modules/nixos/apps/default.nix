{ flake, inputs, ... }:
{ lib, customLib, ... }:
let
  inherit (lib) mkOption types;
in
{
  config._module.args.customLib = flake.lib;
  imports = with inputs; [
    quadlet-nix.nixosModules.quadlet
    helper-tools.nixosModules.podman-sops
    ./podman.nix
    ./forgejo
    ./garage
    ./immich
    ./librespeed
    ./seafile
    ./traefik
    ./pocket
    ./tinyauth
    ./minecraft
    ./beszel
  ];
  options.custom.apps = {
    settings = {
      domain = mkOption {
        type = types.str;
        default = "example.com";
        description = "The domain name to use for all apps.";
      };
      cpus = mkOption {
        type = types.str;
        default = "";
        description = "The cpu core(s) that performance-intensive apps will be limited to.";
      };
    };
  }
  // customLib.mkContainerOptions [
    {
      id = 2000;
      name = "forgejo";
      tags = {
        default = "14-rootless";
        mariadb = "10.11";
      };
    }
    {
      id = 2001;
      name = "garage";
      tags.default = "v2.1.0";
    }
    {
      id = 2002;
      name = "immich";
      tags = {
        default = "release";
        redis = "9";
        postgres = "14-vectorchord0.4.3-pgvectors0.2.0";
      };
    }
    {
      id = 2003;
      name = "seafile";
      tags = {
        default = "13.0-latest";
        redis = "8.2";
        mariadb = "10.11";
      };
    }
    {
      id = 2004;
      name = "traefik";
      tags = {
        default = "v3";
        socket-proxy = "latest";
        ddns-updater = "latest";
      };
    }
    {
      id = 2005;
      name = "pocket";
      tags.default = "v2";
    }
    {
      id = 2006;
      name = "tinyauth";
      tags.default = "v4";
    }
    {
      id = 2007;
      name = "minecraft";
      tags.default = "stable";
    }
    {
      # options only
      id = 2008;
      name = "media";
      tags.default = "latest";
    }
    {
      id = 2009;
      name = "beszel";
      tags.default = "latest";
    }
    {
      id = 2010;
      name = "librespeed";
      tags.default = "latest";
    }
  ];
}

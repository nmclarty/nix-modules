{ inputs, lib, config, ... }:
let
  inherit (lib) mkOption types;
  inherit (inputs.helper-tools.lib) mkContainerOptions;
in
{
  imports = [
    ./forgejo
    ./garage
    ./immich
    ./seafile
    ./traefik
    ./pocket
    ./tinyauth
    ./minecraft
    ./beszel
  ];
  options.apps = {
    settings = {
      domain = mkOption {
        type = types.str;
        default = config.custom.server.settings.domain;
        description = ''
          The domain name to use for all apps. Set this to something different from
          the server domain to allow public-facing services to route to that one,
          while allowing internal-facing ones to still work properly.
        '';
      };
      cpus = mkOption {
        type = types.str;
        default = "";
        description = "The cpu core(s) that performance-intensive apps will be limited to.";
      };
    };
    # apps
  } // mkContainerOptions [
    { id = 2000; name = "forgejo"; tag = "13-rootless"; }
    { id = 2001; name = "garage"; tag = "v2.1.0"; }
    { id = 2002; name = "immich"; tag = "release"; }
    { id = 2003; name = "seafile"; tag = "13.0-latest"; }
    { id = 2004; name = "traefik"; tag = "v3"; }
    { id = 2005; name = "pocket"; tag = "v2"; }
    { id = 2006; name = "tinyauth"; tag = "v4"; }
    { id = 2007; name = "minecraft"; tag = "stable"; }
    { id = 2008; name = "media"; tag = "latest"; } # options only
    { id = 2009; name = "beszel"; tag = "latest"; }
  ];
}

{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib)
    mkEnableOption
    mkOption
    types
    filterAttrs
    findFirst
    elem
    attrNames
    ;
in
{
  # Helpers to reduce duplication for server app modules
  apps = rec {
    # Creates system user and group
    # - name (of the user)
    # - id (uid/gid of the user)
    mkUser =
      { name, id }:
      {
        users.${name} = {
          isSystemUser = true;
          description = "${name} container user";
          group = name;
          uid = id;
        };
        groups.${name}.gid = id;
      };

    # Creates standard option set
    # - name (of the user)
    # - id (uid/gid of the user)
    # - tags (container registry tags to use, "tags.default" is expected)
    # - autoStart (start automatically instead of user-interactively)
    mkOptions =
      args@{
        name,
        id,
        tags,
        ...
      }:
      {
        enable = mkEnableOption "Enable ${name}";
        user = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "The user to create and use for ${name}.";
          };
          id = mkOption {
            type = types.int;
            default = id;
            description = "The uid/gid for the user.";
          };
        };
        tags = mkOption {
          type = types.attrsOf types.str;
          default = tags;
          description = "The image tags to use.";
        };
        autoStart = mkOption {
          type = types.bool;
          default = args.autoStart or true;
          description = "If app should be auto started. Only some support this.";
        };
      };

    # Creates systemd service dependencies on other containers
    # - deps (list of container names)
    mkDeps =
      deps:
      let
        services = map (dep: "${dep}.service") deps;
      in
      {
        Requires = services;
        After = services;
      };

    # Creates multiple sops-nix secrets
    # - keys (list of the keys to create secrets for)
    # - sopsFile (string containing the path to the secret file)
    mkSecrets =
      keys: sopsFile:
      builtins.listToAttrs (
        map (key: {
          name = key;
          value = {
            inherit key sopsFile;
          };
        }) keys
      );

    # Returns a list of all apps that should be running.
    # - config (config to check apps for)
    getApps =
      config:
      builtins.attrNames (
        filterAttrs (_: v: v.enable or false && v.autoStart or false) (with config; custom.apps or { })
      );

    # Returns a list of all service containers that should be running.
    # - config (config to check apps for)
    getServices =
      config:
      map (s: "${s}.service") (
        builtins.attrNames (
          filterAttrs (_: v: v.autoStart) (
            with config; if virtualisation ? quadlet then virtualisation.quadlet.containers else { }
          )
        )
      );

    # Returns the name of the first host that has the provided app enabled and running.
    # - flake (flake that has all hosts as output)
    # - app (name of the app)
    findHost =
      { nixosConfigurations, ... }:
      app:
      findFirst (host: elem app (getApps nixosConfigurations.${host}.config)) null (
        attrNames nixosConfigurations
      );
  };
}

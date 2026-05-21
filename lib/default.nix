{ inputs, ... }:
let
  inherit (inputs.nixpkgs.lib)
    mkEnableOption
    mkOption
    types
    ;
in
{
  # Helpers to reduce duplication for server app modules (containers).
  containers = {
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
    mkOptions =
      {
        name,
        id,
        tags,
      }:
      {
        enable = mkEnableOption "Enable ${name}";
        tags = mkOption {
          type = types.attrsOf types.str;
          default = tags;
          description = "The image tags to use.";
        };
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
  };
}

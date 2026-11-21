{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "lock-images";
  runtimeInputs = with pkgs; [
    crane
    git
    jq
  ];
  text = ''
    # usage: lock-images [--update] [nix eval args, e.g. --override-input]
    # run in a flake whose hosts set custom.apps.images.lock from images.lock at its root;
    # locks images missing from it, or re-locks all of them with --update
    update=false
    if [ "''${1:-}" = "--update" ]; then
      update=true
      shift
    fi

    # all images are public, and a stale local registry login gets them denied
    DOCKER_CONFIG=$(mktemp -d)
    export DOCKER_CONFIG
    trap 'rm -rf "$DOCKER_CONFIG"' EXIT

    cd "$(git rev-parse --show-toplevel)"
    old=$(cat images.lock)
    new='{}'

    # a separate assignment, so a failed eval stops the script instead of locking nothing
    refs=$(
      nix eval --json .#nixosConfigurations "$@" \
        --apply 'hosts: builtins.concatMap (host: host.config.custom.apps.images.refs or [ ]) (builtins.attrValues hosts)'
    )
    mapfile -t refs < <(jq -r 'unique[]' <<<"$refs")
    for ref in "''${refs[@]}"; do
      digest=$(jq -r --arg ref "$ref" '.[$ref] // empty' <<<"$old")
      if [ "$update" = true ] || [ -z "$digest" ]; then
        echo "locking $ref" >&2
        digest=$(crane digest "$ref")
      fi
      new=$(jq --arg ref "$ref" --arg digest "$digest" '. + {($ref): $digest}' <<<"$new")
    done

    jq -S . <<<"$new" >images.lock
  '';
}

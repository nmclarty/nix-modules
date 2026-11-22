{ pkgs, perSystem, ... }:
pkgs.writeShellApplication {
  name = "lock-images";
  runtimeInputs = [
    pkgs.crane
    pkgs.git
    perSystem.helper-tools.default
  ];
  text = ''
    # all images are public, and a stale local registry login gets them denied
    DOCKER_CONFIG=$(mktemp -d)
    export DOCKER_CONFIG
    trap 'rm -rf "$DOCKER_CONFIG"' EXIT

    helper-tools images lock "$@"
  '';
}

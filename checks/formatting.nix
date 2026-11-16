{
  pkgs,
  flake,
  perSystem,
  ...
}:
pkgs.runCommand "formatting" { nativeBuildInputs = [ perSystem.self.formatter ]; } ''
  # the formatters edit in place, and the store copy is read-only
  cp -r ${flake} source
  chmod -R +w source
  treefmt --ci --tree-root source
  touch $out
''

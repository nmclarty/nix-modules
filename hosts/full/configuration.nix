{
  flake,
  lib,
  options,
  ...
}:
{
  imports = with flake.nixosModules; [
    base
    server
    ./hardware.nix
  ];

  networking = {
    hostName = "full";
    hostId = "076df79e";
  };

  # example host for testing, so secrets don't actually exist
  sops.validateSopsFiles = false;

  custom.server.backup.remote = "s3:https://s3.example.com/full";

  custom.apps = lib.mapAttrs (_: _: { enable = true; }) (
    lib.filterAttrs (_: o: lib.isOption (o.enable or null)) options.custom.apps
  );
}

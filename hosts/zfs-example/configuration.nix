{ flake, ... }:
{
  imports = with flake.nixosModules; [
    base
    server
    ./hardware.nix
  ];

  networking = {
    hostName = "zfs-example";
    hostId = "076df79e";
  };

  custom.apps = {
    settings.cpus = "12-19";
    beszel.enable = true;
    forgejo.enable = true;
    garage.enable = true;
    immich.enable = true;
    jellyfin.enable = true;
    librespeed.enable = true;
    minecraft.enable = true;
    pocket.enable = true;
    seafile.enable = true;
    tinyauth.enable = true;
    traefik.enable = true;
  };
}

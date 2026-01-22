{ flake, ... }: {
  imports = with flake.nixosModules; [
    disks
    base
    server
    apps
  ];

  # hardware
  networking = {
    hostName = "zfs-example";
    hostId = "076df79e";
  };
  nixpkgs.hostPlatform = "x86_64-linux";

  custom = {
    disks = {
      root = {
        enable = true;
        disks = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
      };
      cold = {
        enable = true;
        disks = [ "/dev/sda" "/dev/sdb" ];
      };
    };
    apps = {
      settings.cpus = "12-19";
      forgejo.enable = true;
      garage.enable = true;
      immich.enable = true;
      seafile.enable = true;
      traefik.enable = true;
      pocket.enable = true;
      tinyauth.enable = true;
      minecraft.enable = true;
      # media.enable = true;
      beszel.enable = true;
    };
  };
}

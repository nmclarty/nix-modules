{ flake, ... }: {
  imports = with flake.nixosModules; [
    disks
    base
    server
  ];

  # hardware
  networking.hostName = "ext4-example";
  nixpkgs.hostPlatform = "aarch64-linux";
  custom = {
    disks.root = {
      enable = true;
      type = "ext4";
      disks = [ "/dev/nvme0n1" ];
    };

    server.ups.type = "server";
  };
}

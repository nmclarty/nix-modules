{ flake, ... }: {
  imports = with flake.modules; [
    nixos.disko
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
  };
}

{ flake, ... }: {
  imports = with flake.modules; [
    nixos.disko
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
  };
}

{ flake, ... }:
{
  imports = [ flake.nixosModules.disks ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "26.05";

  custom = {
    base.secure-boot.enable = true;
    disks = {
      root = {
        enable = true;
        disks = [
          "/dev/nvme0n1"
          "/dev/nvme1n1"
        ];
      };
      cold = {
        enable = true;
        disks = [
          "/dev/sda"
          "/dev/sdb"
        ];
      };
    };
  };
}

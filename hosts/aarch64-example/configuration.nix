{ flake, ... }:
{
  imports = with flake.nixosModules; [
    disks
    base
    server
  ];

  # hardware
  networking = {
    hostName = "aarch64-example";
    hostId = "a7c3e19d";
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "26.05";

  # example host for testing, so secrets don't actually exist
  sops.validateSopsFiles = false;

  custom = {
    base.devel.enable = true;
    disks.root = {
      enable = true;
      disks = [ "/dev/nvme0n1" ];
    };
    server.ups.mode = "server";
  };
}

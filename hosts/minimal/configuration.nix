{ flake, ... }:
{
  imports = with flake.nixosModules; [
    disks
    base
    server
  ];

  # hardware
  networking = {
    hostName = "minimal";
    hostId = "a7c3e19d";
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "26.05";

  # example host for testing, so secrets don't actually exist
  sops.validateSopsFiles = false;

  custom = {
    base.devel.enable = true;
    server.backup.remote = "s3:https://s3.example.com/minimal";
    disks.root = {
      enable = true;
      devices = [ "/dev/nvme0n1" ];
    };
  };
}

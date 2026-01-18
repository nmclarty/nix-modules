{ lib, inputs, config, ... }:
with lib;
let
  cfg = config.custom.disks;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./root/zfs.nix
    ./root/ext4.nix
    ./cold.nix
  ];
  options.custom.disks = {
    root = {
      enable = mkEnableOption "If root disko config should be enabled.";
      type = mkOption {
        type = types.enum [ "ext4" "zfs" ];
        default = "zfs";
        description = "Which filesystem type to use for the root disk";
      };
      disks = mkOption {
        type = with types; listOf str;
        description = "The list of disk devices to use.";
      };
    };
    cold = {
      enable = mkEnableOption "If cold zfs pool config should be enabled.";
      disks = mkOption {
        type = with types; listOf str;
        description = "The list of disk devices to use.";
      };
    };
  };
  config = mkIf cfg.root.enable {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        configurationLimit = 5;
        enable = true;
      };
    };
  };
}

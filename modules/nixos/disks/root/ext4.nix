{ config, lib, ... }:
let
  cfg = config.custom.disks.root;
  firstDisk = builtins.elemAt cfg.disks 0;
in
{
  config = lib.mkIf (cfg.enable && cfg.type == "ext4") {
    assertions = [
      {
        assertion = builtins.length cfg.disks == 1;
        message = "Root disk type 'ext4' requires 1 disk.";
      }
    ];
    disko.devices.disk.${firstDisk} = {
      type = "disk";
      device = firstDisk;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}

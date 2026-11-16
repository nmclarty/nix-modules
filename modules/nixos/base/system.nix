{ lib, ... }:
{
  nix = {
    gc.dates = "monthly";
    optimise.dates = "weekly";
    settings.allowed-users = [ "@wheel" ];
  };

  networking.nftables.enable = true;

  # enable nonfree firmware
  hardware.enableRedistributableFirmware = true;

  # use zram for memory compression
  zramSwap.enable = lib.mkDefault true;
}

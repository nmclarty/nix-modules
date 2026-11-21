{ lib, pkgs, ... }:
{
  nix = {
    gc.dates = "monthly";
    optimise.dates = "weekly";
    settings.allowed-users = [ "@wheel" ];
  };

  networking.nftables.enable = true;

  hardware = {
    # enable nonfree firmware
    enableRedistributableFirmware = true;
    # each CPU loads only its own vendor's microcode, so both are safe on every x86 host
    cpu = lib.mkIf pkgs.stdenv.hostPlatform.isx86 {
      intel.updateMicrocode = true;
      amd.updateMicrocode = true;
    };
  };

  # use zram for memory compression
  zramSwap.enable = lib.mkDefault true;
}

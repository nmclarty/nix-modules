{
  nix = {
    gc.dates = "weekly";
    optimise.dates = "01:00";
    settings.allowed-users = [ "@wheel" ];
  };

  # locale
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
  services.xserver.xkb.layout = "us";

  # enable nonfree firmware
  hardware.enableRedistributableFirmware = true;

  # use zram for memory compression
  zramSwap.enable = true;
}

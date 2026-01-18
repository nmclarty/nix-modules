{ config, flake, ... }: {
  system = {
    stateVersion = "25.05";
    # the full git ref that the system was built from
    configurationRevision = flake.rev or flake.dirtyRev or "unknown";
  };

  # locale
  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";
  services.xserver.xkb.layout = "us";

  # enable nonfree firmware
  hardware.enableRedistributableFirmware = true;

  # use zram for memory compression
  zramSwap.enable = true;

  # nix settings
  sops = {
    secrets."github/token" = { };
    templates."nix/access-token" = {
      owner = "nmclarty";
      content = ''
        access-tokens = github.com=${config.sops.placeholder."github/token"}
      '';
    };
  };
  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
    extraOptions = ''
      !include ${config.sops.templates."nix/access-token".path}
    '';
  };
}

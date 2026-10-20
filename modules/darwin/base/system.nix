{
  nix = {
    gc.interval = [
      {
        Hour = 0;
        Minute = 0;
        Day = 1;
      }
    ]; # monthly
    optimise.interval = [
      {
        Hour = 0;
        Minute = 0;
        Weekday = 1;
      }
    ]; # weekly
    settings.allowed-users = [ "@admin" ];
  };
  security.pam.services.sudo_local.touchIdAuth = true;
}

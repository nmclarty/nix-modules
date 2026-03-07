{
  nix = {
    gc.interval = [
      {
        Hour = 0;
        Minute = 0;
        Weekday = 1;
      }
    ]; # weekly
    optimise.interval = [
      {
        Hour = 1;
        Minute = 0;
      }
    ]; # daily
    settings.allowed-users = [ "@admin" ];
  };
  security.pam.services.sudo_local.touchIdAuth = true;
}

{ pkgs, config, ... }: {
  sops.secrets = {
    "nmclarty/hashedPassword" = { neededForUsers = true; };
    "root/hashedPassword" = { neededForUsers = true; };
  };
  users = {
    mutableUsers = false;
    users.root = {
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets."root/hashedPassword".path;
    };
    users.nmclarty = {
      isNormalUser = true;
      extraGroups = [ "wheel" "systemd-journal" ];
      shell = pkgs.fish;
      uid = 1000;
      hashedPasswordFile = config.sops.secrets."nmclarty/hashedPassword".path;
    };
  };
}

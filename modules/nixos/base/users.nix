{ pkgs, config, ... }:
{
  sops.secrets."root/hashedPassword".neededForUsers = true;
  users = {
    mutableUsers = false;
    users.root = {
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets."root/hashedPassword".path;
    };
  };
}

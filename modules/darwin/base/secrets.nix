{ config, ... }: {
  sops = {
    defaultSopsFile = config.custom.base.secrets.global;
    log = [ "secretChanges" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      # safe since it only contains public keys
      "known_hosts" = { mode = "0444"; };
    };
  };
}

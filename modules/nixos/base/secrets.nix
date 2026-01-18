{ config, ... }: {
  sops = {
    defaultSopsFile = config.custom.base.secrets.global;
    log = [ "secretChanges" ];
    age = {
      generateKey = true;
      sshKeyPaths = [ "/root/.ssh/id_ed25519" ];
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    secrets = {
      # safe since it only contains public keys
      "known_hosts" = { mode = "0444"; };
    };
  };
}

{ config, ... }: {
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.overcommit_memory" = 1; # allow overcommit for redis
  };

  sops.secrets."authorized_keys" = { };
  security.pam = {
    rssh = {
      enable = true;
      settings = {
        cue = true;
        cue_prompt = "Authenticating with ssh-agent...";
        auth_key_file = config.sops.secrets."authorized_keys".path;
      };
    };
    services.sudo.rssh = true;
  };
}

{ config, ... }:
{
  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.overcommit_memory" = 1; # allow overcommit for redis
  };

  # logs are shipped to loki, so the local journal only needs to cover short outages
  services.journald.settings.Journal = {
    Storage = "volatile";
    RuntimeMaxUse = "256M";
  };

  sops.secrets."ssh/authorized_keys" = { };
  security.pam = {
    rssh = {
      enable = true;
      settings = {
        cue = true;
        cue_prompt = "Authenticating with ssh-agent...";
        auth_key_file = config.sops.secrets."ssh/authorized_keys".path;
      };
    };
    services.sudo.rssh = true;
  };

  systemd = {
    enableEmergencyMode = false;
    sleep.settings.Sleep = {
      AllowSuspend = "no";
      AllowHibernation = "no";
    };
    settings.Manager = {
      RuntimeWatchdogSec = "15s";
      RebootWatchdogSec = "30s";
    };
  };
}

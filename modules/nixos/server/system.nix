{ config, ... }:
{
  boot.tmp.cleanOnBoot = true;
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.overcommit_memory" = 1; # allow overcommit for redis
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

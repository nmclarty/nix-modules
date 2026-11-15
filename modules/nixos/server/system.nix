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

  # servers are administered as root
  security.sudo.enable = false;

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

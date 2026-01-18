{ pkgs, config, lib, ... }:
# optional/extra feature configurations
let
  conNames = builtins.attrNames (config.virtualisation.quadlet.containers or { });
  # create a list of services without dashes in their names
  # (indicating that they are main containers, not dependencies)
  # and turn that list into rust-motd container entries
  containers =
    if conNames != [ ] then
      lib.concatStringsSep "\n    "
        (map (s: ''container display-name="${s}" docker-name="/${s}"'')
          (lib.filter (s: ! lib.strings.hasInfix "-" s) conNames)
        ) else "";
  podman =
    if containers != "" then ''
      docker title="Podman" socket="unix:///run/podman/podman.sock" {
        ${containers}
      }
    ''
    else "";
in
{
  systemd.services.rust-motd = {
    description = "Update the motd using rust-motd";
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ rust-motd ];
    script = ''
      rust-motd ${config.sops.templates."rust-motd/config.kdl".path} > /run/rust-motd/motd
    '';
  };
  systemd.timers.rust-motd = {
    description = "Timer for rust-motd updates";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "0";
      OnUnitActiveSec = "60s";
    };
  };
  systemd.tmpfiles.rules = [
    "f+ /run/rust-motd/cg_stats.toml"
    "f+ /run/rust-motd/motd"
  ];
  sops.templates."rust-motd/config.kdl" = {
    restartUnits = [ "rust-motd.service" ];
    content = ''
      global {
        version "1.0"
        progress-empty-character "-"
      }
      components {
        uptime prefix="Uptime:"
        load-avg format="Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}"
        cg-stats state-file="/run/rust-motd/cg_stats.toml" threshold=0.01
        ${podman}
      }
    '';
  };
}

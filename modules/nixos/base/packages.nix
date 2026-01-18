{ pkgs, ... }: {
  # programs
  programs = {
    # fish is mainly configured in home manager
    fish.enable = true;
    # to fix vscode remote development
    nix-ld.enable = true;
    # command-not-found doesn't work with flakes
    command-not-found.enable = false;
  };

  # disable generating man cache (because fish causes it to hang)
  documentation.man.generateCaches = false;

  # keep editor config to use micro
  security.sudo.extraConfig = ''Defaults env_keep += "EDITOR"'';

  # allow btop to monitor system power info
  security.wrappers.btop = {
    enable = true;
    owner = "root";
    group = "root";
    source = "${pkgs.btop}/bin/btop";
    capabilities = "cap_perfmon=ep";
  };
  systemd.tmpfiles.rules = [
    "z /sys/class/powercap/intel-rapl:0/energy_uj 0444"
  ];
}

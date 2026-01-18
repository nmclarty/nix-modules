{ pkgs, ... }: {
  home = {
    packages = with pkgs; [
      # shell
      fd
      zoxide
      bat
      ripgrep
      # utilities
      gdu
      wget
      doggo
      moreutils
      yq-go
      goaccess
      iperf
      # secrets
      sops
      pwgen
      ssh-to-age
    ];
  };
}

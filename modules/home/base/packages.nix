{ pkgs, ... }:
{
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
      iperf
      # secrets
      sops
      pwgen
      ssh-to-age
    ];
  };
}

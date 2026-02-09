{ pkgs, osConfig, ... }:
{
  imports = [ ./functions.nix ];
  home = {
    packages = with pkgs; [
      eza
      figlet
      lolcat
    ];
    sessionVariables.EDITOR = "micro";
  };

  programs = {
    py-motd = {
      enable = true;
      settings = {
        backup.enable = with osConfig; services ? py-backup && services.py-backup.enable;
        update.inputs = [
          "nixpkgs"
          "nix-modules"
          "helper-tools"
        ];
      };
    };
    # disable generating man caches (fish enables it, but it's pretty slow)
    man.generateCaches = false;
    fish = {
      enable = true;
      shellAbbrs = {
        # general
        ll = "eza -lh --git";
        la = "eza -lh --git --all";
        lt = "eza -lh --git --tree --git-ignore --total-size";
      };
      loginShellInit = ''
        # ssh agent
        set -l op_sock $(path normalize "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock")
        set -l win_sock $(path normalize "$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock")
        if test -S "$op_sock"
            # if 1password agent socket exists, use it
            set -gx SSH_AUTH_SOCK $op_sock
        else if test -S "$win_sock"
            # if wsl2-ssh-agent socket exists, use it
            set -gx SSH_AUTH_SOCK $win_sock
        end

        # homebrew
        set -l brew /opt/homebrew/bin/brew
        if test -f "$brew"
            set -gx HOMEBREW_NO_ENV_HINTS 1
            eval ($brew shellenv)
        end

        # motd
        set -l disallowed_terminals "zed" "vscode"
        if test "$SHLVL" -eq 1; and not contains "$TERM_PROGRAM" $disallowed_terminals
            # show hostname if we're connecting remotely
            if test -n "$SSH_CONNECTION"
                hostname | figlet | lolcat -f
            end

            # display rust-motd, removing blank lines
            set -l motd "/run/rust-motd/motd"
            if test -f "$motd"
                cat "$motd" | grep -v '^$'
            end

            # display py_motd
            if type -q py_motd
                py_motd
            end
        end
      '';
    };
  };
}

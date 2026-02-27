{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) filter strings;
in
{
  home = {
    packages = with pkgs; [
      # abbrs
      eza
      # functions
      lolcat
      docker-client
      xxd
      goaccess
    ];
    sessionVariables = {
      EDITOR = "micro";
    };
  };

  programs = {
    py-motd = {
      enable = true;
      system.services = filter (s: !strings.hasInfix "-" s) (
        builtins.attrNames (osConfig.virtualisation.quadlet.containers or { })
      );
      update.inputs = [
        "nixpkgs"
        "nix-modules"
        "helper-tools"
      ];
    };

    fish = {
      enable = true;
      shellAbbrs = {
        # general
        ll = "eza -lh --git";
        la = "eza -lh --git --all";
        lt = "eza -lh --git --tree --git-ignore --total-size";
      };
      interactiveShellInit = ''
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
      '';
      functions = {
        fish_greeting = ''
          if status is-login; and not contains "$TERM_PROGRAM" "zed" "vscode"
            py_motd
          end
        '';
        fish_prompt = ''
          echo -n "$(hostname | lolcat -f)"
          set_color brgreen; echo -n " [$(basename $PWD)]";
          set_color bryellow; echo -n " > ";
        '';
        helper-health = "docker inspect $argv[1] | yq -oj '.[0].State.Health'";
        helper-ps = "docker ps --format='table {{.Names}}\t{{.Status}}\t{{.Image}}'";
        helper-hostid = "head -c4 /dev/urandom | xxd -p";
        helper-logs = ''
          cat /srv/utils/traefik/logs/access.log \
          | grep "$argv[1]@docker" (if test "(count $argv)" -eq 0; echo "-v"; end) \
          | goaccess --log-format TRAEFIKCLF
        '';
        rrun = "rustc $argv[1].rs && ./$argv[1]";
      };
    };
  };
}

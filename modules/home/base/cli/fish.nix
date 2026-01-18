{ pkgs, osConfig, ... }: {
  # dependencies
  home.packages = with pkgs; [
    # abbrs
    eza
    # functions
    figlet
    lolcat
    xxd
    # both
    docker-client
  ];
  programs = {
    # disable generating man cache (fish enables it, but it's pretty slow)
    man.generateCaches = false;

    py-motd = {
      enable = pkgs.stdenv.isLinux;
      settings = {
        backup.enable = with osConfig; services ? py-backup && services.py-backup.enable;
        update.inputs = [ "nixpkgs" "helper-tools" ];
      };
    };

    fish = {
      enable = true;
      loginShellInit = ''
        # env vars
        set -gx EDITOR micro

        # ssh agent
        set op_sock $(path normalize "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock")
        set win_sock $(path normalize "$XDG_RUNTIME_DIR/wsl2-ssh-agent.sock")
        if test -S "$op_sock"
            # if 1password agent socket exists, use it
            set -gx SSH_AUTH_SOCK $op_sock
        else if test -S "$win_sock"
            # if wsl2-ssh-agent socket exists, use it
            set -gx SSH_AUTH_SOCK $win_sock
        end

        # homebrew
        set -gx HOMEBREW_NO_ENV_HINTS 1
        set brew /opt/homebrew/bin/brew
        if test -f "$brew"
            # load homebrew environment variables
            eval ($brew shellenv)
        end
      '';
      interactiveShellInit = ''
        # motd
        if test "$SHLVL" -eq 1
            # show hostname if we're connecting remotely
            if test -n "$SSH_CONNECTION"
                hostname | figlet | lolcat -f
            end

            # display rust-motd, removing blank lines
            set motd "/run/rust-motd/motd"
            if test -f "$motd"
                cat "$motd" | grep -v '^$'
            end

            # display py_motd
            if type -q py_motd
                py_motd
            end
        end
      '';
      shellAbbrs = {
        # general
        ll = "eza -lh --git";
        la = "eza -lh --git --all";
        lt = "eza -lh --git --tree --git-ignore --total-size";
        # docker
        dc = "docker compose";
        de = "docker exec -it";
      };
      functions = {
        fish_greeting = "";
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

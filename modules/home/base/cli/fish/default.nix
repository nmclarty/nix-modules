{ pkgs, osConfig, ... }:
{
  home = {
    packages = with pkgs; [
      eza
      figlet
      lolcat
      xxd
      docker-client
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
      loginShellInit = builtins.readFile ./login.fish;
      interactiveShellInit = builtins.readFile ./interactive.fish;
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

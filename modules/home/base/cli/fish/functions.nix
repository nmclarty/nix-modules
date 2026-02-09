{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lolcat
    docker-client
    xxd
    goaccess
  ];
  programs.fish.functions = {
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
}

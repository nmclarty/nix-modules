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

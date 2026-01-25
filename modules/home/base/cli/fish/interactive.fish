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

# rsv completions

# Helper: detect distro ID from /etc/os-release
function __rsv_distro
    grep '^ID=' /etc/os-release 2>/dev/null | string replace 'ID=' '' | string trim -c '"'
end

# Helper: system sv dirs (one per line)
function __rsv_sys_svdirs
    set -l distro (__rsv_distro)
    switch $distro
        case void
            echo /etc/sv
        case devuan
            echo /etc/sv
            echo /usr/share/runit/sv.current
        case artix
            echo /etc/runit/sv
        case '*'
            echo /etc/sv
    end
end

# Helper: system runsvdir path
function __rsv_sys_runsvdir
    set -l distro (__rsv_distro)
    switch $distro
        case devuan artix
            echo /etc/runit/runsvdir/default
        case '*'
            echo /var/service
    end
end

# Helper: user sv dir
function __rsv_user_svdir
    test -n "$RUNIT_SVDIR"; and echo "$RUNIT_SVDIR"; or echo "$HOME/.runit/sv"
end

# Helper: user runsvdir
function __rsv_user_runsvdir
    test -n "$RUNIT_RUNSVDIR"; and echo "$RUNIT_RUNSVDIR"; or echo "$HOME/.runit/runsvdir"
end

# Helper: is a specific subcommand active?
function __rsv_cmd_is
    contains -- $argv[1] (commandline -opc)
end

# Helper: no rsv subcommand seen yet
function __rsv_no_cmd
    set -l tokens (commandline -opc)
    for cmd in start stop restart reload enable disable status list logs edit new init once watch doctor log-setup log-remove finish-setup
        if contains -- $cmd $tokens
            return 1
        end
    end
    return 0
end

# Helper: all services from both system and user dirs, labeled (root)/(user)
function __rsv_all_services
    for dir in (__rsv_sys_svdirs)
        test -d $dir || continue
        for svc in (ls $dir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            printf "%s\troot\n" $svc
        end
    end
    set -l udir (__rsv_user_svdir)
    if test -d $udir
        for svc in (ls $udir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            printf "%s\tuser\n" $svc
        end
    end
end

# Helper: enabled services from both system and user runsvdirs, labeled (root)/(user)
function __rsv_enabled_services
    set -l sys_rundir (__rsv_sys_runsvdir)
    if test -d $sys_rundir
        for svc in (ls $sys_rundir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            printf "%s\troot\n" $svc
        end
    end
    set -l usr_rundir (__rsv_user_runsvdir)
    if test -d $usr_rundir
        for svc in (ls $usr_rundir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            printf "%s\tuser\n" $svc
        end
    end
end

# Helper: disabled services — not symlinked in their respective runsvdir
function __rsv_disabled_services
    set -l sys_rundir (__rsv_sys_runsvdir)
    for dir in (__rsv_sys_svdirs)
        test -d $dir || continue
        for svc in (ls $dir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            if not test -L "$sys_rundir/$svc"
                printf "%s\troot\n" $svc
            end
        end
    end
    set -l udir (__rsv_user_svdir)
    set -l usr_rundir (__rsv_user_runsvdir)
    if test -d $udir
        for svc in (ls $udir 2>/dev/null | grep -v 'current\|supervise\|\.supervisor')
            if not test -L "$usr_rundir/$svc"
                printf "%s\tuser\n" $svc
            end
        end
    end
end

# --- Flags (before any subcommand) ---
complete -c rsv -f -n __rsv_no_cmd -a "--user" -d "operate on user services"
complete -c rsv -f -n "__rsv_no_cmd; and not contains -- --as-user (commandline -opc)" \
    -a "--as-user" -d "manage another user's services"
complete -c rsv -f -n "test (commandline -opc)[-1] = --as-user" \
    -a "(getent passwd | cut -d: -f1)"

# --- Subcommands ---
complete -c rsv -f -n __rsv_no_cmd -a "start"        -d "start a service"
complete -c rsv -f -n __rsv_no_cmd -a "stop"         -d "stop a service"
complete -c rsv -f -n __rsv_no_cmd -a "restart"      -d "restart a service"
complete -c rsv -f -n __rsv_no_cmd -a "reload"       -d "reload a service"
complete -c rsv -f -n __rsv_no_cmd -a "enable"       -d "enable a service"
complete -c rsv -f -n __rsv_no_cmd -a "disable"      -d "disable a service"
complete -c rsv -f -n __rsv_no_cmd -a "status"       -d "show service status"
complete -c rsv -f -n __rsv_no_cmd -a "list"         -d "list all services"
complete -c rsv -f -n __rsv_no_cmd -a "logs"         -d "tail service logs"
complete -c rsv -f -n __rsv_no_cmd -a "edit"         -d "open run script in \$EDITOR"
complete -c rsv -f -n __rsv_no_cmd -a "new"          -d "scaffold a new service"
complete -c rsv -f -n __rsv_no_cmd -a "init"         -d "start user runsvdir (user mode only)"
complete -c rsv -f -n __rsv_no_cmd -a "once"         -d "run a service once without supervision"
complete -c rsv -f -n __rsv_no_cmd -a "watch"        -d "auto-refreshing status"
complete -c rsv -f -n __rsv_no_cmd -a "doctor"       -d "check for common runit problems"
complete -c rsv -f -n __rsv_no_cmd -a "log-setup"    -d "add a log service to an existing service"
complete -c rsv -f -n __rsv_no_cmd -a "log-remove"   -d "remove the log service from a service"
complete -c rsv -f -n __rsv_no_cmd -a "finish-setup" -d "scaffold a finish script for a service"

# --- Service name completions ---

complete -c rsv -f -n "__rsv_cmd_is start"   -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is stop"    -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is restart" -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is reload"  -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is disable" -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is status"  -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is logs"    -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is edit"    -a "(__rsv_all_services)"

complete -c rsv -f -n "__rsv_cmd_is enable" \
    -a "(__rsv_disabled_services)"
complete -c rsv -f -n "__rsv_cmd_is enable; and not contains -- --now (commandline -opc)" \
    -a "--now" -d "also start the service immediately"

complete -c rsv -f -n "__rsv_cmd_is new; and not contains -- --log (commandline -opc)" \
    -a "--log" -d "also scaffold a log service"

complete -c rsv -f -n "__rsv_cmd_is once"  -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is watch" -a "(__rsv_enabled_services)"

complete -c rsv -f -n "__rsv_cmd_is log-setup"    -a "(__rsv_all_services)"
complete -c rsv -f -n "__rsv_cmd_is log-remove"   -a "(__rsv_all_services)"
complete -c rsv -f -n "__rsv_cmd_is finish-setup" -a "(__rsv_all_services)"

complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --errors (commandline -opc)" \
    -a "--errors" -d "show only error/warn/crit/fail lines"
complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --level (commandline -opc)" \
    -a "--level"  -d "filter by level e.g. error,warn"
complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --lines (commandline -opc)" \
    -a "--lines"  -d "show last N matching lines (default 10)"

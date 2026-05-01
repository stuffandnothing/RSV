# rsv completions

# Helper: is --user flag present in the current commandline?
function __rsv_user_mode
    contains -- --user (commandline -opc)
end

# Helper: effective sv dir based on mode
function __rsv_svdir
    if __rsv_user_mode
        echo (test -n "$RUNIT_SVDIR"; and echo "$RUNIT_SVDIR"; or echo "$HOME/.runit/sv")
    else
        echo /etc/runit/sv
    end
end

# Helper: is a specific subcommand active?
function __rsv_cmd_is
    contains -- $argv[1] (commandline -opc)
end

# Helper: no rsv subcommand seen yet
function __rsv_no_cmd
    set -l tokens (commandline -opc)
    for cmd in start stop restart reload enable disable status list logs edit new init doctor log-setup log-remove
        if contains -- $cmd $tokens
            return 1
        end
    end
    return 0
end

# Helper: list all services (excluding internals)
function __rsv_all_services
    set -l dir (__rsv_svdir)
    if test -d $dir
        ls $dir | grep -v 'current\|supervise\|\.supervisor'
    end
end

# Helper: list only enabled services (have a symlink in runsvdir)
function __rsv_enabled_services
    if __rsv_user_mode
        set -l rundir (test -n "$RUNIT_RUNSVDIR"; and echo $RUNIT_RUNSVDIR; or echo "$HOME/.runit/runsvdir")
        if test -d $rundir
            ls $rundir | grep -v 'current\|supervise\|\.supervisor'
        end
    else
        ls /etc/runit/runsvdir/default 2>/dev/null | grep -v 'current\|supervise'
    end
end

# Helper: list only disabled services
function __rsv_disabled_services
    set -l all (__rsv_all_services)
    set -l enabled (__rsv_enabled_services)
    for svc in $all
        if not contains $svc $enabled
            echo $svc
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
complete -c rsv -f -n __rsv_no_cmd -a "start"   -d "start a service"
complete -c rsv -f -n __rsv_no_cmd -a "stop"    -d "stop a service"
complete -c rsv -f -n __rsv_no_cmd -a "restart" -d "restart a service"
complete -c rsv -f -n __rsv_no_cmd -a "reload"  -d "reload a service"
complete -c rsv -f -n __rsv_no_cmd -a "enable"  -d "enable a service"
complete -c rsv -f -n __rsv_no_cmd -a "disable" -d "disable a service"
complete -c rsv -f -n __rsv_no_cmd -a "status"  -d "show service status"
complete -c rsv -f -n __rsv_no_cmd -a "list"    -d "list all services"
complete -c rsv -f -n __rsv_no_cmd -a "logs"    -d "tail service logs"
complete -c rsv -f -n __rsv_no_cmd -a "edit"    -d "open run script in \$EDITOR"
complete -c rsv -f -n __rsv_no_cmd -a "new"     -d "scaffold a new service"
complete -c rsv -f -n __rsv_no_cmd -a "init"      -d "start user runsvdir (user mode only)"
complete -c rsv -f -n __rsv_no_cmd -a "doctor"    -d "check for common runit problems"
complete -c rsv -f -n __rsv_no_cmd -a "log-setup"  -d "add a log service to an existing service"
complete -c rsv -f -n __rsv_no_cmd -a "log-remove" -d "remove the log service from a service"

# --- Service name completions ---

# start/stop/restart/reload/disable/status/logs: enabled services
complete -c rsv -f -n "__rsv_cmd_is start"   -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is stop"    -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is restart" -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is reload"  -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is disable" -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is status"  -a "(__rsv_enabled_services)"
complete -c rsv -f -n "__rsv_cmd_is logs"    -a "(__rsv_enabled_services)"

# edit: all services (enabled or not)
complete -c rsv -f -n "__rsv_cmd_is edit"    -a "(__rsv_all_services)"

# enable: disabled services + --now (only offer --now if not already present)
complete -c rsv -f -n "__rsv_cmd_is enable" \
    -a "(__rsv_disabled_services)"
complete -c rsv -f -n "__rsv_cmd_is enable; and not contains -- --now (commandline -opc)" \
    -a "--now" -d "also start the service immediately"

# new: --log flag (only if not already present)
complete -c rsv -f -n "__rsv_cmd_is new; and not contains -- --log (commandline -opc)" \
    -a "--log" -d "also scaffold a log service"

# log-setup / log-remove: all services
complete -c rsv -f -n "__rsv_cmd_is log-setup"  -a "(__rsv_all_services)"
complete -c rsv -f -n "__rsv_cmd_is log-remove" -a "(__rsv_all_services)"

# logs: level filter flags (only if not already present)
complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --errors (commandline -opc)" \
    -a "--errors" -d "show only error/warn/crit/fail lines"
complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --level (commandline -opc)" \
    -a "--level"  -d "filter by level e.g. error,warn"
complete -c rsv -f -n "__rsv_cmd_is logs; and not contains -- --lines (commandline -opc)" \
    -a "--lines"  -d "show last N matching lines (default 10)"

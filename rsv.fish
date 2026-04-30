# rsv completions

set -l commands start stop restart reload enable disable status list init
set -l user_svdir (test -n "$RUNIT_SVDIR"; and echo "$RUNIT_SVDIR"; or echo "$HOME/.runit/sv")
set -l sys_svdir /etc/runit/sv

# Helper: is --user flag present?
# Completions always run as the invoking user, so id -u is never 0 here.
# Instead check whether the commandline starts with sudo to pick system mode.
function __rsv_user_mode
    __fish_seen_subcommand_from --user
end

# Helper: effective sv dir based on mode
function __rsv_svdir
    if __rsv_user_mode
        echo $user_svdir
    else
        echo $sys_svdir
    end
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
        set -l rundir (test -n "$RUNIT_RUNSVDIR"; and echo "$RUNIT_RUNSVDIR"; or echo "$HOME/.runit/runsvdir")
        if test -d $rundir
            ls $rundir | grep -v 'current\|supervise\|\.supervisor'
        end
    else
        ls /etc/runit/runsvdir/default | grep -v 'current\|supervise'
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

# --- Flag ---
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "--user" -d "operate on user services"

# --- Subcommands ---
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "start"   -d "start a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "stop"    -d "stop a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "restart" -d "restart a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "reload"  -d "reload a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "enable"  -d "enable a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "disable" -d "disable a service"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "status"  -d "show service status"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "list"    -d "list all services"
complete -c rsv -f -n "not __fish_seen_subcommand_from $commands" \
    -a "init"    -d "start user runsvdir (user mode only)"

# --- Service name completions ---

# start/restart/reload/disable/status: complete enabled services
complete -c rsv -f -n "__fish_seen_subcommand_from start restart reload disable status" \
    -a "(__rsv_enabled_services)"

# stop: complete enabled services
complete -c rsv -f -n "__fish_seen_subcommand_from stop" \
    -a "(__rsv_enabled_services)"

# enable: complete only disabled services
complete -c rsv -f -n "__fish_seen_subcommand_from enable" \
    -a "(__rsv_disabled_services)"

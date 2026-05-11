#compdef rsv
# rsv zsh completions
# Copy to a directory in $fpath (e.g. /usr/share/zsh/site-functions/_rsv)

_rsv() {
    local context state state_descr line
    typeset -A opt_args

    local -a commands
    commands=(
        'start:start a service'
        'stop:stop a service'
        'restart:restart a service'
        'reload:reload a service'
        'enable:enable a service'
        'disable:disable a service'
        'status:show service status'
        'list:list all services'
        'logs:tail service logs'
        'edit:open run script in $EDITOR'
        'new:scaffold a new service'
        'init:start user runsvdir (user mode only)'
        'once:run a service once without supervision'
        'watch:auto-refreshing status'
        'doctor:check for common runit problems'
        'log-setup:add a log service to an existing service'
        'log-remove:remove the log service from a service'
        'finish-setup:scaffold a finish script for a service'
    )

    local user_mode=1  # non-root defaults to user mode
    [[ $EUID -eq 0 ]] && user_mode=0
    [[ "${words[(r)sudo]}" == "sudo" || "${words[(r)doas]}" == "doas" ]] && user_mode=0
    [[ "${words[(r)--user]}" == "--user" ]] && user_mode=1

    local svdir runsvdir
    local -a svdirs
    if [[ $user_mode -eq 1 ]]; then
        svdir="${RUNIT_SVDIR:-$HOME/.runit/sv}"
        svdirs=("$svdir")
        runsvdir="${RUNIT_RUNSVDIR:-$HOME/.runit/runsvdir}"
    else
        local _distro
        _distro=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
        case "$_distro" in
            void)   svdir="/etc/sv";       svdirs=("/etc/sv");                               runsvdir="/var/service" ;;
            devuan) svdir="/etc/sv";       svdirs=("/etc/sv" "/usr/share/runit/sv.current"); runsvdir="/etc/runit/runsvdir/default" ;;
            artix)  svdir="/etc/runit/sv"; svdirs=("/etc/runit/sv");                         runsvdir="/etc/runit/runsvdir/default" ;;
            *)      svdir="/etc/sv";       svdirs=("/etc/sv");                               runsvdir="/var/service" ;;
        esac
    fi

    _rsv_all() {
        local _d
        for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] && ls "$_d" 2>/dev/null
        done | grep -v 'current\|supervise\|\.supervisor' | sort -u
    }
    _rsv_enabled() {
        [[ -d "$runsvdir" ]] && ls "$runsvdir" 2>/dev/null \
            | grep -v 'current\|supervise\|\.supervisor'
    }
    _rsv_disabled() {
        local -a all enabled
        all=($(_rsv_all))
        enabled=($(_rsv_enabled))
        for svc in $all; do
            (( ${enabled[(I)$svc]} )) || echo "$svc"
        done
    }

    _arguments -C \
        '--user[operate on user services]' \
        '--as-user[manage another users services]:user:_users' \
        '1: :->cmd' \
        '*: :->args'

    case $state in
        cmd)
            _describe 'command' commands
            ;;
        args)
            case $words[2] in
                enable)
                    _arguments \
                        '--now[also start the service immediately]' \
                        '*: :(($(_rsv_disabled)))'
                    ;;
                start|stop|restart|reload|disable|status)
                    local -a svcs
                    svcs=($(_rsv_enabled))
                    _values 'service' $svcs
                    ;;
                logs)
                    _arguments \
                        '--errors[show only error/warn/crit/fail lines]' \
                        '--level[filter by log level]:levels:(error warn info crit fail)' \
                        '--lines[number of lines to show]:N:' \
                        '*: :(($(_rsv_enabled)))'
                    ;;
                once|watch)
                    local -a svcs
                    svcs=($(_rsv_enabled))
                    _values 'service' $svcs
                    ;;
                edit|log-setup|log-remove|finish-setup)
                    local -a svcs
                    svcs=($(_rsv_all))
                    _values 'service' $svcs
                    ;;
                new)
                    _arguments \
                        '--log[also scaffold a log service]' \
                        '*: :'
                    ;;
            esac
            ;;
    esac
}

_rsv "$@"

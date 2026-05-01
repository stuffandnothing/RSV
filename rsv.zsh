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
        'init:start user runsvdir (user mode only)'
        'doctor:check for common runit problems'
        'log-setup:add a log service to an existing service'
    )

    local user_mode=0
    [[ "${words[(r)--user]}" == "--user" ]] && user_mode=1

    local svdir runsvdir
    if [[ $user_mode -eq 1 ]]; then
        svdir="${RUNIT_SVDIR:-$HOME/.runit/sv}"
        runsvdir="${RUNIT_RUNSVDIR:-$HOME/.runit/runsvdir}"
    else
        svdir="/etc/runit/sv"
        runsvdir="/etc/runit/runsvdir/default"
    fi

    _rsv_all() {
        [[ -d "$svdir" ]] && ls "$svdir" 2>/dev/null \
            | grep -v 'current\|supervise\|\.supervisor'
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
                start|stop|restart|reload|disable|status|logs)
                    local -a svcs
                    svcs=($(_rsv_enabled))
                    _values 'service' $svcs
                    ;;
                log-setup)
                    local -a svcs
                    svcs=($(_rsv_all))
                    _values 'service' $svcs
                    ;;
            esac
            ;;
    esac
}

_rsv "$@"

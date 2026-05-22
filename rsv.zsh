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

    # Distro-aware system paths
    local svdir runsvdir
    local -a svdirs
    local _distro
    _distro=$(grep '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    case "$_distro" in
        void)   svdir="/etc/sv";       svdirs=("/etc/sv");                               runsvdir="/var/service" ;;
        devuan) svdir="/etc/sv";       svdirs=("/etc/sv" "/usr/share/runit/sv.current"); runsvdir="/etc/runit/runsvdir/default" ;;
        artix)  svdir="/etc/runit/sv"; svdirs=("/etc/runit/sv");                         runsvdir="/etc/runit/runsvdir/default" ;;
        *)      svdir="/etc/sv";       svdirs=("/etc/sv");                               runsvdir="/var/service" ;;
    esac

    local user_svdir="${RUNIT_SVDIR:-$HOME/.runit/sv}"
    local user_runsvdir="${RUNIT_RUNSVDIR:-$HOME/.runit/runsvdir}"

    # Build parallel name/description arrays for _describe, labeled (root)/(user)
    _rsv_all() {
        local -a names descs _d svc
        for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] || continue
            for svc in $(ls "$_d" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                names+=("$svc"); descs+=("root")
            done
        done
        if [[ -d "$user_svdir" ]]; then
            for svc in $(ls "$user_svdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                names+=("$svc"); descs+=("user")
            done
        fi
        _describe 'service' names descs
    }
    _rsv_enabled() {
        local -a names descs svc
        if [[ -d "$runsvdir" ]]; then
            for svc in $(ls "$runsvdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                names+=("$svc"); descs+=("root")
            done
        fi
        if [[ -d "$user_runsvdir" ]]; then
            for svc in $(ls "$user_runsvdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                names+=("$svc"); descs+=("user")
            done
        fi
        _describe 'service' names descs
    }
    _rsv_disabled() {
        local -a names descs _d svc
        for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] || continue
            for svc in $(ls "$_d" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                [[ -L "$runsvdir/$svc" ]] && continue
                names+=("$svc"); descs+=("root")
            done
        done
        if [[ -d "$user_svdir" ]]; then
            for svc in $(ls "$user_svdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                [[ -L "$user_runsvdir/$svc" ]] && continue
                names+=("$svc"); descs+=("user")
            done
        fi
        _describe 'service' names descs
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
            local cmd=""
            local w
            for w in ${words[2,-1]}; do
                [[ "$w" == --* ]] && continue
                cmd="$w"
                break
            done
            case $cmd in
                enable)
                    _arguments \
                        '--now[also start the service immediately]' \
                        '*: :->svcs'
                    [[ $state == svcs ]] && _rsv_disabled
                    ;;
                start|stop|restart|reload|disable|status|once|watch|logs)
                    _rsv_enabled
                    ;;
                edit|log-setup|log-remove|finish-setup)
                    _rsv_all
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

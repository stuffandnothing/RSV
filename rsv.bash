# rsv bash completions
# Source in ~/.bashrc or drop in /etc/bash_completion.d/rsv

_rsv() {
    local cur prev words cword
    _init_completion || return

    local commands="start stop restart reload enable disable status list logs edit new init once watch doctor log-setup log-remove finish-setup"

    local user_mode=1  # non-root defaults to user mode
    local has_sudo=0
    for word in "${words[@]}"; do
        [[ "$word" == "sudo" || "$word" == "doas" ]] && has_sudo=1
        [[ "$word" == "--user" || "$word" == "--as-user" ]] && { user_mode=1; break; }
    done
    [[ $has_sudo -eq 1 ]] && user_mode=0
    [[ $EUID -eq 0 ]] && user_mode=0

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
        local enabled
        enabled=$(_rsv_enabled)
        for svc in $(_rsv_all); do
            echo "$enabled" | grep -qx "$svc" || echo "$svc"
        done
    }

    # Complete --as-user argument with usernames
    if [[ "$prev" == "--as-user" ]]; then
        COMPREPLY=($(compgen -u -- "$cur"))
        return
    fi

    # Complete --level argument
    if [[ "$prev" == "--level" ]]; then
        COMPREPLY=($(compgen -W "error warn info crit fail" -- "$cur"))
        return
    fi

    local cmd=""
    for word in "${words[@]:1}"; do
        [[ "$word" == --* ]] && continue
        if [[ " $commands " == *" $word "* ]]; then
            cmd="$word"
            break
        fi
    done

    case "$cmd" in
        "")
            COMPREPLY=($(compgen -W "$commands --user --as-user" -- "$cur"))
            ;;
        enable)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--now" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_rsv_disabled)" -- "$cur"))
            fi
            ;;
        start|stop|restart|reload|disable|status)
            COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            ;;
        logs)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--errors --level --lines" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            fi
            ;;
        once|watch)
            COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            ;;
        edit|log-setup|log-remove|finish-setup)
            COMPREPLY=($(compgen -W "$(_rsv_all)" -- "$cur"))
            ;;
        new)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--log" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _rsv rsv

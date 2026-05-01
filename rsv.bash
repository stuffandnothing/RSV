# rsv bash completions
# Source in ~/.bashrc or drop in /etc/bash_completion.d/rsv

_rsv() {
    local cur prev words cword
    _init_completion || return

    local commands="start stop restart reload enable disable status list logs edit new init doctor log-setup log-remove"

    local user_mode=0
    for word in "${words[@]}"; do
        [[ "$word" == "--user" || "$word" == "--as-user" ]] && { user_mode=1; break; }
    done

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
        edit|log-setup|log-remove)
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

# rsv bash completions
# Source in ~/.bashrc or drop in /etc/bash_completion.d/rsv

_rsv() {
    local cur prev words cword
    _init_completion || return

    local commands="start stop restart reload enable disable status list logs init"

    local user_mode=0
    for word in "${words[@]}"; do
        [[ "$word" == "--user" ]] && { user_mode=1; break; }
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
            COMPREPLY=($(compgen -W "$commands --user" -- "$cur"))
            ;;
        enable)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--now" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_rsv_disabled)" -- "$cur"))
            fi
            ;;
        start|stop|restart|reload|disable|status|logs)
            COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            ;;
    esac
}

complete -F _rsv rsv

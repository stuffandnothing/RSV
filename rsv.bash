# rsv bash completions
# Source in ~/.bashrc or drop in /etc/bash_completion.d/rsv

_rsv() {
    local cur prev words cword
    _init_completion || return

    local commands="start stop restart reload enable disable status list logs edit new init once watch doctor log-setup log-remove finish-setup"

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

    _rsv_all() {
        local _d
        { for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] && ls "$_d" 2>/dev/null
          done
          [[ -d "$user_svdir" ]] && ls "$user_svdir" 2>/dev/null
        } | grep -v 'current\|supervise\|\.supervisor' | sort -u
    }
    _rsv_enabled() {
        { [[ -d "$runsvdir" ]]      && ls "$runsvdir"      2>/dev/null
          [[ -d "$user_runsvdir" ]] && ls "$user_runsvdir" 2>/dev/null
        } | grep -v 'current\|supervise\|\.supervisor' | sort -u
    }
    _rsv_no_log() {
        local _d svc
        for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] || continue
            for svc in $(ls "$_d" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                [[ -f "$_d/$svc/log/run" ]] || echo "$svc"
            done
        done
        [[ -d "$user_svdir" ]] && for svc in $(ls "$user_svdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
            [[ -f "$user_svdir/$svc/log/run" ]] || echo "$svc"
        done
    }
    _rsv_no_finish() {
        local _d svc
        for _d in "${svdirs[@]}"; do
            [[ -d "$_d" ]] || continue
            for svc in $(ls "$_d" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
                [[ -f "$_d/$svc/finish" ]] || echo "$svc"
            done
        done
        [[ -d "$user_svdir" ]] && for svc in $(ls "$user_svdir" 2>/dev/null | grep -v 'current\|supervise\|\.supervisor'); do
            [[ -f "$user_svdir/$svc/finish" ]] || echo "$svc"
        done
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
        once)
            COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            ;;
        watch)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--interval" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$(_rsv_enabled)" -- "$cur"))
            fi
            ;;
        edit|log-remove)
            COMPREPLY=($(compgen -W "$(_rsv_all)" -- "$cur"))
            ;;
        log-setup)
            COMPREPLY=($(compgen -W "$(_rsv_no_log)" -- "$cur"))
            ;;
        finish-setup)
            COMPREPLY=($(compgen -W "$(_rsv_no_finish)" -- "$cur"))
            ;;
        list)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--uptime -u" -- "$cur"))
            fi
            ;;
        new)
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--log --user" -- "$cur"))
            fi
            ;;
    esac
}

complete -F _rsv rsv

# RSV — Handoff Document

This file is a briefing for continuing development in a new conversation.
Delete it when no longer needed.

## What this is

`rsv` is a bash script — a friendly wrapper around runit's `sv` command.
Think OpenRC's `rc-service`/`rc-update` but for runit.
Supports system services (root) and user services (non-root), with shell completions for fish, bash, and zsh.

## File layout

```
rsv          # main script (bash)
rsv.fish     # fish completions (also installed to ~/.config/fish/completions/rsv.fish)
rsv.bash     # bash completions
rsv.zsh      # zsh completions
Install.sh   # installer (handles root and user-local installs)
README.md    # user-facing docs
Todo.md      # open issues (see below)
HANDOFF.md   # this file
```

## Current commands

start, stop, restart, reload, enable, disable, status, list, logs, edit,
new, init, once, watch, doctor, log-setup, log-remove, finish-setup

## Key flags

--user, --as-user <user>, --now (enable), --log (new), --errors (logs),
--level <levels> (logs), --lines N (logs)

## Architecture notes

### Mode detection
- Non-root → user mode automatically (SVDIR=~/.runit/sv)
- Root → system mode (SVDIR=/etc/runit/sv)
- `--user` forces user mode; `--as-user bob` impersonates bob with r/w check

### Flag parsing
Two-pass loop strips flags into variables (NOW, LOG_LEVEL, LOG_LINES,
WITH_LOG, AS_USER) before `set --` rebuilds positional args.

### runsv race conditions
Adding/removing a symlink in RUNSVDIR is async — runsvdir needs time to
start/kill the runsv process. `enable --now`, `log-setup`, and `log-remove`
all poll `sv status` until "unable to open supervise" appears/disappears
before continuing. The wait loop uses 0.2s sleep, max 25 iterations (5s).

### Log pipeline
Per-service logs: svlogd writes to `/var/log/<name>/current` (system) or
`~/.runit/log/<name>/current` (user). `cmd_logs` parses the destination
from `log/run` via awk.
Global log fallback: filters with grep, strips `[sudo]` audit lines.
All log output goes through `_colorize_log` (awk, fflush for live mode).

### sudo + environment
`sudo` strips EDITOR and NO_COLOR.
- EDITOR: recovered via `su - $SUDO_USER -c 'printenv EDITOR'`
- NO_COLOR: recovered by reading `/proc/$PPID/status` → parent PID →
  `/proc/<parent>/environ` (works because we're root).
- Colors also auto-disabled when stdout is not a tty (`! -t 1`).

### Completions mode detection
Fish/bash/zsh completions check for `sudo`/`doas` in the command line to
decide whether to offer system or user services. Non-root with no sudo →
user services. Root or sudo present → system services.

### _suggest_service
When a service name isn't found, tries single-char deletion matches and
shared-prefix heuristic to suggest the correct name (catches typos like
`bluethoothd` → `bluetoothd`).

## Docker test environment (runit on other inits)

```sh
#Dockerfile and compose
docker compose build
docker compose run rsv

```

For a more realistic test with actual supervision:
```sh
docker run -it --rm --privileged --name rsv-test \
    -v $(pwd):/rsv \
    voidlinux/voidlinux /sbin/init
```

## Things that burned time (don't repeat)

- Fish completion `set -l` at file top-level goes out of scope before
  completion functions are called — all service-dir lookups must be
  hardcoded inside the functions, not stored in variables.
- svlogd writes `current` to the DESTINATION directory (e.g.
  `/var/log/NetworkManager/current`), NOT inside the service's `log/` dir.
- svlogd log files contain binary bytes — always pass `-a` to grep.
- `runsv` only picks up `log/run` on startup, not dynamically.
  Requires disable + wait + enable cycle, not just `sv restart`.
- NetworkManager logs via syslog not stdout, so its per-service svlogd
  log is empty. Fall back to global log when `current` is empty.

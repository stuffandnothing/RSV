# rsv

A friendly wrapper around runit's `sv` command, with system and user service support.

<details>
<summary>Why?</summary>

I don't hate myself and this is a nice wrapper. \
The inspiration was OpenRC's `rc-service` and `rc-update`. \
I hate doing `ln -s /etc/runit/sv/service_name /run/runit/service` — that gets annoying fast, and I don't have to think about it with this.

</details>

<details>
<summary>Other runit service managers</summary>

Before starting this project I wasn't aware of existing tools. Here's how they compare:

| Tool | Language | Last Updated | Notes |
|------|----------|-------------|-------|
| [rsv](https://github.com/JojiiOfficial/rsv) | Rust | ~3 years ago | Abandoned, `list` is raw `sv status` dump |
| [vsv](https://github.com/bahamas10/vsv) | Rust | ~3 years ago | Rewrite of bash-vsv, Void-focused, Abandoned |
| [bash-vsv](https://github.com/bahamas10/bash-vsv) | Bash | ~3 years ago | Original vsv, Void-focused, Abandoned |
| [rsm](https://gitea.artixlinux.org/linuxer/Runit-Service-Manager) | Bash | ~5 years ago | Attributed fork of bash-vsv for Artix, adds `logs`/`errorlogs`, shows internal runit dirs as services, Abandoned |
| [roonit](https://github.com/19742bytes/roonit) | C | ~5 years ago | Void-focused, very basic, Abandoned |

### `list` benchmark (Artix, 47 services)

| Tool | Time | Output |
|------|------|--------|
| `rsv` (JojiiOfficial) | ~14ms | Raw unsorted `sv status` dump, no colors, includes internal dirs |
| `rsm` | ~168ms | Formatted, but includes `current`/`supervise` as services |
| `rsv` (this) | ~32ms | Sorted, colored, filters internals, enabled/disabled/uptime distinction |
| `bash-vsv` | ~168ms | Estimated, shares the same core codebase as `rsm` |
| others | ? | Untested, don't use Void |

`rsm` is a properly attributed fork of `bash-vsv`, retargeted at Artix's paths with a couple of added subcommands (`logs`/`errorlogs`). The core service-listing/status logic is unchanged from `bash-vsv`, which is why the two benchmark identically.

If you use Void and want to benchmark, I will add those.

</details>

## Installation

Run the install script as root (system-wide) or as your user (local):

```sh
sudo ./Install.sh   # installs to /usr/local/bin, system completion dirs
./Install.sh        # installs to ~/.local/bin, user completion dirs
```

<details>
<summary>Manual installation</summary>

### System-wide (as root)

```sh
 install -Dm755 rsv      /usr/local/bin/rsv
 install -Dm644 rsv.bash /usr/share/bash-completion/completions/rsv
 install -Dm644 rsv.fish /usr/share/fish/vendor_completions.d/rsv.fish
 install -Dm644 rsv.zsh  /usr/share/zsh/site-functions/_rsv
 install -Dm644 rsv.1    /usr/share/man/man1/rsv.1
```


### User-local

```sh
install -m755 rsv      ~/.local/bin/rsv
install -m644 rsv.bash ~/.local/share/bash-completion/completions/rsv
install -m644 rsv.fish ~/.config/fish/completions/rsv.fish
install -m644 rsv.zsh  ~/.local/share/zsh/site-functions/_rsv
```

> **Note:** For sudo rsv and man pages to work, system-wide installation is recommended.

</details>

## Usage

```
rsv [--user] [--as-user <user>] <command> [service] [flags]
```

System services require root. User services are selected automatically when not root, or explicitly with `--user`.

### Commands

| Command | Description |
|---|---|
| `start <service...>` | start one or more services |
| `stop <service...>` | stop one or more services |
| `restart <service...>` | restart one or more services |
| `reload <service...>` | reload one or more services |
| `enable <service...>` | enable one or more services |
| `disable <service...>` | disable one or more services |
| `status [service...]` | status of listed (or all enabled) services |
| `list` | list all available services and their state |
| `logs [service]` | tail logs for a service, or the global log |
| `edit <service...>` | open the run script(s) in `$EDITOR` |
| `new <service>` | scaffold a new service |
| `init` | start the user runsvdir supervisor (user mode only) |
| `doctor` | check for common runit configuration problems |
| `once <service...>` | run one or more services once without supervision |
| `watch [service]` | auto-refreshing status display |
| `log-setup <service...>` | add a svlogd log service to one or more services |
| `log-remove <service...>` | remove the svlogd log service from one or more services |
| `finish-setup <service...>` | scaffold a finish script for one or more services |

### Flags

| Flag | Applies to | Description |
|---|---|---|
| `--user` | all | operate on user services (auto-set when not root) |
| `--as-user <user>` | all | manage another user's services (requires r/w access) |
| `--now` | `enable` | also start the service immediately |
| `--log` | `new` | also scaffold a log service |
| `-u`, `--uptime` | `list` | show uptime for running services |
| `--interval <N>` | `watch` | refresh every N seconds (default 2) |
| `--errors` | `logs` | show only error/warn/crit/fail lines |
| `--level <levels>` | `logs` | filter by log level, e.g. `--level error,warn` |
| `--lines <N>` | `logs` | show last N matching lines (default 10) |

## Examples

```sh
# system services
sudo rsv status
sudo rsv restart NetworkManager
sudo rsv enable --now sshd
sudo rsv list
sudo rsv list -u
sudo rsv logs NetworkManager
sudo rsv logs NetworkManager --errors
sudo rsv logs NetworkManager --level info,warn

# watch services refresh every 5 seconds
sudo rsv watch --interval 5

# user services
rsv status
rsv enable --now pipewire
rsv logs syncthing

# create a new service with logging
sudo rsv new myapp --log
sudo rsv edit myapp
sudo rsv enable --now myapp

# manage another user's services (requires r/w access to their runit dirs)
sudo rsv --as-user bob enable pipewire
sudo rsv --as-user bob logs pipewire
```

If you run a command against the wrong mode, rsv will reexec as root via sudo or doas

```
$ rsv enable metalog
[sudo] password for cytop:
ok: enabled 'metalog'
```

## User services

User services live in `~/.runit/sv` with symlinks in `~/.runit/runsvdir`. Start the user supervisor at login by adding this to your session init (`~/.profile`, `~/.xinitrc`, etc.):

```sh
rsv --user init
```
## Privilege handling

rsv escalates privileges only through the user's existing `sudo` or `doas` configuration. When a command needs root and wasn't invoked with one already, rsv re-execs itself via whichever is installed (`sudo` preferred, `doas` as fallback) and returns an error if neither is available. It never bypasses or replaces the system's authentication policy.

> **Note:** `doas` requires an explicit rule in `/etc/doas.conf` (e.g. `permit :wheel cmd /usr/bin/rsv`) for this to work — without one, `doas` will refuse silently rather than rsv being at fault.

`--as-user <user>` is a separate mechanism and does **not** escalate privileges. It only checks that the invoking (already-privileged) user has read/write access to the target user's runit directories — or their nearest existing parent directory, if the target doesn't exist yet — and operates entirely within those existing filesystem permissions.

Paths can be overridden with environment variables:

| Variable | Default |
|---|---|
| `RUNIT_SVDIR` | `~/.runit/sv` |
| `RUNIT_RUNSVDIR` | `~/.runit/runsvdir` |
| `RUNIT_LOG` | `~/.runit/log/everything/current` |

## Paths

### Artix

| | System | User |
|---|---|---|
| service definitions | `/etc/runit/sv` | `~/.runit/sv` |
| enabled services | `/etc/runit/runsvdir/default` | `~/.runit/runsvdir` |
| global log | `/var/log/everything/current` | `~/.runit/log/everything/current` |
| per-service log | `/var/log/<service>/current` | `~/.runit/log/<service>/current` |

### Void

| | System | User |
|---|---|---|
| service definitions | `/etc/sv` | `~/.runit/sv` |
| enabled services | `/var/service` | `~/.runit/runsvdir` |
| global log | `/var/log/sv/everything/current` | `~/.runit/log/everything/current` |
| per-service log | `/var/log/sv/<service>/current` | `~/.runit/log/<service>/current` |

### Devuan

| | System | User |
|---|---|---|
| service definitions | `/etc/sv` | `~/.runit/sv` |
| enabled services | `/etc/runit/runsvdir/default` | `~/.runit/runsvdir` |
| global log | `/var/log/runit/everything/current` | `~/.runit/log/everything/current` |
| per-service log | `/var/log/<service>/current` | `~/.runit/log/<service>/current` |

## Init detection

rsv detects whether runit is actually running by checking if PID 1's process name is runit or runsvdir, falling back to a pgrep scan for either process — this correctly handles containers where runit runs as PID 2+ under an init shim like tini or docker-init. 

```
$ rsv list
==> Available user services (in /home/cytop/.runit/sv):
warn: service directory /home/cytop/.runit/sv does not exist
warn: runit is not running
 ___________________________________
< rsv is for runit, not for systemd >
 -----------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
> **Note:** Each taunt (systemd, OpenRC, dinit, s6, 66, and sysvinit) is pre-rendered and base64-embedded, so there's no runtime `cowsay` dependency. I got the idea due to `pacman`'s `repo-elephant`.

## Per-service logging

Services that write to stdout/stderr can have a dedicated svlogd log service added with `log-setup`:

```sh
sudo rsv log-setup myapp
```

This creates a `log/run` script that pipes the service's output through `svlogd` into its own log directory. Once active, `rsv logs myapp` reads from there directly instead of filtering the global log.

> **Note:** Some services (e.g. NetworkManager) log via syslog rather than stdout, so their per-service log will be empty. The global log is the right source for those.

To remove per-service logging:

```sh
sudo rsv log-remove myapp
```

Log data is left in place — remove it manually if no longer needed.

## Shell completions

Completions for fish, bash, and zsh are included. The install script places them automatically.

Commands, flags, and service names are all completed. Flags only appear for the commands they apply to — `--now` for `enable`, `--log` and `--user` for `new`, `-u`/`--uptime` for `list`, `--interval` for `watch`, and `--errors`/`--level`/`--lines` for `logs`. `log-setup` and `finish-setup` only suggest services that don't already have a log service or finish script respectively.

## NO_COLOR

rsv respects the [`NO_COLOR`](https://no-color.org) convention. When running under `sudo`, it recovers the variable from the parent shell's environment since sudo strips it. `TERM=dumb` also disables color.

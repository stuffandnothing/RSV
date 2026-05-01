# Rsv

A friendly wrapper around runit's `sv` command, with system and user service support.

<details>
<summary>Why?</summary>

I don't hate myself and this is a nice wrapper.

The inspiration was OpenRC's `rc-service` and `rc-update`.
I hate doing `ln -s /etc/runit/sv/service_name /run/runit/service` — that gets annoying fast, and I don't have to think about it with this.
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
```

### User-local

```sh
install -m755 rsv      ~/.local/bin/rsv
install -m644 rsv.bash ~/.local/share/bash-completion/completions/rsv
install -m644 rsv.fish ~/.config/fish/completions/rsv.fish
install -m644 rsv.zsh  ~/.local/share/zsh/site-functions/_rsv
```

> **Note:** For `sudo rsv` to work, system-wide installation is recommended.

</details>

## Usage

```
rsv [--user] [--as-user <user>] <command> [service] [flags]
```

System services require root. User services are selected automatically when not root, or explicitly with `--user`.

### Commands

| Command | Description |
|---|---|
| `start <service>` | start a service |
| `stop <service>` | stop a service |
| `restart <service>` | restart a service |
| `reload <service>` | reload a service |
| `enable <service>` | enable a service |
| `disable <service>` | disable a service |
| `status [service]` | status of one or all enabled services |
| `list` | list all available services and their state |
| `logs [service]` | tail logs for a service, or the global log |
| `edit <service>` | open the service run script in `$EDITOR` |
| `new <service>` | scaffold a new service |
| `init` | start the user runsvdir supervisor (user mode only) |
| `doctor` | check for common runit configuration problems |
| `log-setup <service>` | add a svlogd log service to an existing service |
| `log-remove <service>` | remove the svlogd log service from a service |

### Flags

| Flag | Description |
|---|---|
| `--user` | operate on user services (auto-set when not root) |
| `--as-user <user>` | manage another user's services (requires r/w access) |
| `--now` | with `enable`: also start the service immediately |
| `--log` | with `new`: also scaffold a log service |
| `--errors` | with `logs`: show only error/warn/crit/fail lines |
| `--level <levels>` | with `logs`: filter by log level, e.g. `--level error,warn` |
| `--lines <N>` | with `logs`: show last N matching lines (default 10) |

## Examples

```sh
# system services
sudo rsv status
sudo rsv restart NetworkManager
sudo rsv enable --now sshd
sudo rsv logs NetworkManager
sudo rsv logs NetworkManager --errors
sudo rsv logs NetworkManager --level info,warn

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

If you run a command against the wrong mode, rsv will tell you:

```
error: service 'metalog' not found in /home/user/.runit/sv
hint:  did you mean: sudo rsv status metalog
```

## User services

User services live in `~/.runit/sv` with symlinks in `~/.runit/runsvdir`. Start the user supervisor at login by adding this to your session init (`~/.profile`, `~/.xinitrc`, etc.):

```sh
rsv --user init
```

Paths can be overridden with environment variables:

| Variable | Default |
|---|---|
| `RUNIT_SVDIR` | `~/.runit/sv` |
| `RUNIT_RUNSVDIR` | `~/.runit/runsvdir` |
| `RUNIT_LOG` | `~/.runit/log/everything/current` |

## Paths

| | System | User |
|---|---|---|
| service definitions | `/etc/runit/sv` | `~/.runit/sv` |
| enabled services | `/etc/runit/runsvdir/default` | `~/.runit/runsvdir` |
| global log | `/var/log/everything/current` | `~/.runit/log/everything/current` |
| per-service log | `/var/log/<service>/current` | `~/.runit/log/<service>/current` |

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

Commands, flags, and service names are all completed. Flags like `--now`, `--errors`, `--level`, and `--lines` only appear for the commands they apply to.

## NO_COLOR

rsv respects the [`NO_COLOR`](https://no-color.org) convention.

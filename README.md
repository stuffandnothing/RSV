# rsv

A friendly wrapper around runit's `sv` command, with system and user service support.
I 
## Installation

Run the install script as root (system-wide) or as your user (local):

```sh
sudo ./Install.sh   # installs to /usr/local/bin, system completion dirs
./Install.sh        # installs to ~/.local/bin, user completion dirs
```
<details>
<summary>Manual Installation </summary>
if for some reason you dont like automatic?

### System-wide (as root)

~~~sh
install -Dm755 rsv      /usr/local/bin/rsv
install -Dm644 rsv.bash /usr/share/bash-completion/completions/rsv
install -Dm644 rsv.fish /usr/share/fish/vendor_completions.d/rsv.fish
install -Dm644 rsv.zsh  /usr/share/zsh/site-functions/_rsv
~~~

### User-local
~~~sh
install -m755 rsv      ~/.local/bin/rsv
install -m644 rsv.bash ~/.local/share/bash-completion/completions/rsv
install -m644 rsv.fish ~/.config/fish/completions/rsv.fish
install -m644 rsv.zsh  ~/.local/share/zsh/site-functions/_rsv
~~~

> **Note:** For `sudo rsv` to work, system-wide installation is recommended.

</details>
Both paths install shell completions for fish, bash, and zsh.

## Usage

```
rsv [--user] [--now] [--errors] [--level <levels>] <command> [service]
```

System services require root. User services are selected automatically when not root, or explicitly with `--user`.

| command | description |
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
| `init` | start the user runsvdir supervisor (user mode only) |

### Flags

| flag | description |
|---|---|
| `--user` | operate on user services (auto-set when not root) |
| `--now` | with `enable`: also start the service immediately |
| `--errors` | with `logs`: show only error/warn/crit/fail lines |
| `--level <levels>` | with `logs`: filter by log level, e.g. `--level error,warn` |

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

| variable | default |
|---|---|
| `RUNIT_SVDIR` | `~/.runit/sv` |
| `RUNIT_RUNSVDIR` | `~/.runit/runsvdir` |
| `RUNIT_LOG` | `~/.runit/log/everything/current` |

## Paths

| | system | user |
|---|---|---|
| service definitions | `/etc/runit/sv` | `~/.runit/sv` |
| enabled services | `/etc/runit/runsvdir/default` | `~/.runit/runsvdir` |
| logs | `/var/log/everything/current` | `~/.runit/log/everything/current` |

## Shell completions

Completions for fish, bash, and zsh are included. The install script places them automatically. To load manually:

```sh
# fish (auto-loaded from this directory)
cp rsv.fish ~/.config/fish/completions/rsv.fish

# bash — add to ~/.bashrc
source /path/to/rsv.bash

# zsh — place in a directory on $fpath
cp rsv.zsh /usr/share/zsh/site-functions/_rsv
```

## NO_COLOR

rsv respects the [`NO_COLOR`](https://no-color.org) convention.
# rsv

A friendly wrapper around runit's `sv` command, with system and user service support.

## Installation

```sh
sudo cp rsv /usr/local/bin/rsv
chmod +x /usr/local/bin/rsv

# fish completions
cp rsv.fish ~/.config/fish/completions/rsv.fish
```

## Usage

```
rsv [--user] <command> [service]
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
| `init` | start the user runsvdir supervisor (user mode only) |

## Examples

```sh
# system services
sudo rsv status
sudo rsv restart NetworkManager

# user services
rsv status
rsv --user start pipewire
rsv --user enable wireplumber
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

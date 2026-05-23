# Todo

## Completions
- [x] `finish-setup` completion should only suggest services that don't already have a `finish` script
- [x] `log-setup` completion should only suggest services without an existing `log/run`

## Logs
- [x] `rsv logs` historical scan overlaps with `tail -f` — some lines appear twice
- [x] `rsv watch` interval is hardcoded to 2s — add `--interval N` flag

## doctor
- [x] Check if a service has `log/run` but the log supervisor is down (runsv not managing it)

## Misc
- [x] `rsv disable` doesn't wait for the service to fully stop before removing the symlink
- [x] `rsv new` doesn't validate the service name (spaces, slashes, etc.)
- [x] NO_COLOR detection via `/proc` may not work in containers — fallback needed
- [x] Debug code
- [x] `rsv new` doesn't validate the service name (spaces, slashes, etc.)
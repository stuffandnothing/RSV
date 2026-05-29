#!/bin/bash

# Install rsv system-wide
/rsv/Install.sh --no-confirm

# Install systemctl shim if present
[[ -f /rsv-ng-systemctl/systemctl ]] && \
    install -Dm755 /rsv-ng-systemctl/systemctl /usr/bin/systemctl
# Start system-level runsvdir
runsvdir /etc/runit/runsvdir/default &
RUNSVDIR_PID=$!

# Start user-level runsvdir as testuser
su -c "XDG_RUNTIME_DIR=/run/user/1000 runsvdir /home/testuser/.runit/runsvdir &" testuser

sleep 0.5

echo ""
echo "  Artix runit dev container"
echo "  system runsvdir running (PID $RUNSVDIR_PID)"
echo "  user runsvdir running as testuser"
echo ""
echo "  Test system services (as root):"
echo "    rsv status"
echo ""
echo "  Test user services:"
echo "    su testuser"
echo "    rsv status"
echo ""
echo "  Test systemctl shim:"
echo "    systemctl status"
echo "    systemctl is-active <service>"
echo ""

exec "${@:-bash}"

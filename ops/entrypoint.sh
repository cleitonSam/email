#!/bin/sh
set -e

# If arguments are provided, pass them to keila directly (e.g. eval, rpc)
if [ "$#" -gt 0 ]; then
  exec /opt/app/bin/keila "$@"
fi

echo "==> Running migrations and seeds..."
/opt/app/bin/keila eval "Keila.ReleaseTasks.init()"

echo "==> Ensuring default SMTP sender for all projects..."
/opt/app/bin/keila eval "Keila.ReleaseTasks.ensure_default_sender()"

echo "==> Starting Fluxo Email MKT..."
exec /opt/app/bin/keila start

#!/bin/bash

ERROR_STATUS=0
set -e

function log_execute() {
    set -x
    "$@"
    { set +x; } 2>/dev/null
}

# authenticate with gcp
/scripts/auth.sh
# configure kubernetes
/scripts/config_k8s.sh

kubectl port-forward "$DATABASE_DEPLOYMENT" $DATABASE_PORT:$DATABASE_FORWARD_PORT -n default &

# Wait until the connection is available or timeout after 10 seconds
timeout 10 /scripts/db_wait.sh

PORT_FORWARD_PID=$!

sleep 2
log_execute "$@" || ERROR_STATUS=$?

kill $PORT_FORWARD_PID

exit $ERROR_STATUS

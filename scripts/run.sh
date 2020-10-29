#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

echo "INFO: start TON node..."
echo "INFO: log file = ${TON_WORK_DIR}/node.log"

V_CPU=`nproc`
USE_THREADS=$((V_CPU - 2))

# shellcheck disable=SC2086
"${TON_BUILD_DIR}/validator-engine/validator-engine" -v "1" -t "$USE_THREADS" ${ENGINE_ADDITIONAL_PARAMS} \
    -C "${TON_WORK_DIR}/etc/ton-global.config.json" --db "${TON_WORK_DIR}/db" > "${TON_WORK_DIR}/node.log" 2>&1 &

sleep 2
VAL_PID=`ps -ax | grep "validator\-engine" | awk '{print $1}'`
echo "Engine PID: $VAL_PID"

exit 0

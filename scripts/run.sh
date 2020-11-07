#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

verb="${1:-1}"
echo "INFO: start TON node..."
echo "INFO: log file = ${TON_WORK_DIR}/node.log"

if [[ "$(uname)" == "Linux" ]];then
    V_CPU=`nproc`
else
    V_CPU=`sysctl -n hw.ncpu`
fi

USE_THREADS=$((V_CPU - 2))

echo
echo "${TON_BUILD_DIR}/validator-engine/validator-engine -v $verb -t $USE_THREADS ${ENGINE_ADDITIONAL_PARAMS} -C ${TON_WORK_DIR}/etc/ton-global.config.json --db ${TON_WORK_DIR}/db > ${TON_WORK_DIR}/node.log"
echo

"${TON_BUILD_DIR}/validator-engine/validator-engine" -v "$verb" -t "$USE_THREADS" ${ENGINE_ADDITIONAL_PARAMS} \
    -C "${TON_WORK_DIR}/etc/ton-global.config.json" --db "${TON_WORK_DIR}/db" > "${TON_WORK_DIR}/node.log" 2>&1 &

sleep 2
VAL_PID=`ps -ax | grep "validator\-engine" | awk '{print $1}'`
echo "Engine PID: $VAL_PID"

exit 0

#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

verb="${1:-1}"

if [[ "$(uname)" == "Linux" ]];then
    V_CPU=`nproc`
else
    V_CPU=`sysctl -n hw.ncpu`
fi

USE_THREADS=$((V_CPU - 2))
SERVICE_FILE="/etc/systemd/system/ton-node.service"

SVC_FILE_CONTENTS=$(cat <<-_ENDCNT_
[Unit]
Description=TON Validator Node
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
StandardOutput=append:${TON_LOG_DIR}/node.log
StandardError=append:${TON_LOG_DIR}/node.log
LimitNOFILE=2048000

ExecStart=$CALL_VE -v $verb -t $USE_THREADS ${ENGINE_ADDITIONAL_PARAMS} -C ${TON_WORK_DIR}/etc/ton-global.config.json --db ${TON_WORK_DIR}/db

[Install]
WantedBy=multi-user.target
_ENDCNT_
)

echo "${SVC_FILE_CONTENTS}" > ./tmp.txt
sudo mv -f ./tmp.txt ${SERVICE_FILE}

echo
echo "============================================="
cat ${SERVICE_FILE}
echo "============================================="
echo

echo "To restart updated service run all follow commands:"
echo
echo "sudo systemctl daemon-reload"
echo "sudo systemctl disable ton-node"
echo "sudo systemctl enable ton-node"
echo "sudo service ton-node restart"
echo
exit 0

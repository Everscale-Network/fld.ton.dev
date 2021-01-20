#!/bin/bash

# (C) Sergey Tyurin  2020-01-11 19:00:00

# Disclaimer
##################################################################################################################
# You running this script/function means you will not blame the author(s)
# if this breaks your stuff. This script/function is provided AS IS without warranty of any kind. 
# Author(s) disclaim all implied warranties including, without limitation, 
# any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
# In no event shall author(s) be held liable for any damages whatsoever 
# (including, without limitation, damages for loss of business profits, business interruption, 
# loss of business information, or other pecuniary loss) arising out of the use of or inability 
# to use the script or documentation. Neither this script/function, 
# nor any part of it other than those parts that are explicitly copied from others, 
# may be republished without author(s) express written permission. 
# Author(s) retain the right to alter this disclaimer at any time.
##################################################################################################################

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

verb="${1:-1}"
OS_SYSTEM=`uname`
if [[ "${OS_SYSTEM}" == "Linux" ]];then
    V_CPU=`nproc`
else
    V_CPU=`sysctl -n hw.ncpu`
    echo "###-ERROR: Daemon for FreeBSD not implemented yet"
    exit 1
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
sudo chown root:root ${SERVICE_FILE}
sudo chmod 644 ${SERVICE_FILE}
[[ "$(hostnamectl |grep 'Operating System'|awk '{print $3}')" == "CentOS" ]] && sudo chcon system_u:object_r:etc_t:s0 ${SERVICE_FILE}

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

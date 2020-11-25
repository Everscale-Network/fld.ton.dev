#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

LR_CFG=${SCRIPT_DIR}/rot_nodelog.cfg
LR_LOG=${TON_WORK_DIR}/rot_nodelog.log
LR_STATUS=${TON_WORK_DIR}/rot_nodelog.status


logrotate -s $LR_STATUS -l $LR_LOG -f $LR_CFG

exit 0

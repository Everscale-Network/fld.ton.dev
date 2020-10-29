#!/bin/bash -eE

# usage: tg-check_node_sync_status.sh [T - timeout sec] [alarm to tg if time > N]

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`

echo "cd to $SCRIPT_DIR"
cd $SCRIPT_DIR
. "${SCRIPT_DIR}/env.sh"
[[ ! -d $HOME/logs ]] && mkdir -p $HOME/logs

ALARM_TIME_DIFF=$2
ALARM_TIME_DIFF=${ALARM_TIME_DIFF:=100}
SLEEP_TIMEOUT=$1
SLEEP_TIMEOUT=${SLEEP_TIMEOUT:="60"}

# ===================================================
GET_CHAIN_DATE() {
    OS_SYSTEM=`uname`
    ival="${1}"
    if [[ "$OS_SYSTEM" == "Linux" ]];then
        echo "$(date  +'%F %T %Z' -d @$ival)"
    else
        echo "$(date -r $ival +'%F %T %Z')"
    fi
}
# ===================================================

CALL_VC="${TON_BUILD_DIR}/validator-engine-console/validator-engine-console -k ${KEYS_DIR}/client -p ${KEYS_DIR}/server.pub -a 127.0.0.1:3030 -t 5"

while(true)
do

VEC_OUTPUT=$($CALL_VC -c "getstats" -c "quit")

# echo "VEC output:"
CURR_TD_NOW=`echo "${VEC_OUTPUT}" | grep unixtime | awk '{print $2}'`
CHAIN_TD=`echo "${VEC_OUTPUT}" | grep masterchainblocktime | awk '{print $2}'`
TIME_DIFF=$((CURR_TD_NOW - CHAIN_TD))
CURR_TD_NOW=`GET_CHAIN_DATE "$CURR_TD_NOW"`

if [[ -z $CHAIN_TD ]];then
    echo "CurrTime: $CURR_TD_NOW --- No masterchain blocks received yet."
    sleep $SLEEP_TIMEOUT
    continue
fi

CHAIN_TD=`GET_CHAIN_DATE "$CHAIN_TD"`

echo "CurrTime: $CURR_TD_NOW TimeDiff: $TIME_DIFF" | tee -a ~/logs/time-diff.log

if [[ $TIME_DIFF -gt $ALARM_TIME_DIFF ]];then
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "ALARM! NODE out of sync. TimeDiff: $TIME_DIFF" 2>&1 > /dev/null
fi

sleep $SLEEP_TIMEOUT
done

exit 0

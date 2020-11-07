#!/bin/bash -eE


SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

[[ ! -d $HOME/Logs ]] && mkdir -p $HOME/Logs

SLEEP_TIMEOUT=$1
SLEEP_TIMEOUT=${SLEEP_TIMEOUT:="10"}
MAX_TIME_DIFF=10

# ===================================================
GET_CHAIN_DATE() {
    OS_SYSTEM=`uname`
    ival="${1}"
    if [[ "$OS_SYSTEM" == "Linux" ]];then
        echo "$(date  +'%Y-%m-%d %H:%M:%S' -d @$ival)"
    else
        echo "$(date -r $ival +'%Y-%m-%d %H:%M:%S')"
    fi
}
# ===================================================

first_sync="no"

while(true)
do

VEC_OUTPUT=$("${TON_BUILD_DIR}/validator-engine-console/validator-engine-console" \
    -a 127.0.0.1:3030 \
    -k "${KEYS_DIR}/client" \
    -p "${KEYS_DIR}/server.pub" \
    -c "getstats" -c "quit")

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

echo "CurrTime: $CURR_TD_NOW TimeDiff: $TIME_DIFF" | tee -a ~/Logs/time-diff.log

if [[ $TIME_DIFF -lt $MAX_TIME_DIFF  ]];then
    if [[ $first_sync == "yes" ]];then
        exit 0
    else
        first_sync="yes"
    fi
fi

sleep $SLEEP_TIMEOUT
done

exit 0

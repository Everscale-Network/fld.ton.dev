#!/bin/bash -eE

set -o pipefail
# set -u
# set -x

function not_found(){
    if [[ -z $ACC_STATUS ]];then
    echo
    echo "Account not found!"
    echo
    fi
}

trap not_found EXIT

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

MY_ACCOUNT=`cat "${KEYS_DIR}/${HOSTNAME}.addr"`
[[ -z $MY_ACCOUNT ]] && echo " Can't find ${KEYS_DIR}/${HOSTNAME}.addr"

ACCOUNT=$1
ACCOUNT=${ACCOUNT:=$MY_ACCOUNT}

CALL_LT="${TON_BUILD_DIR}/lite-client/lite-client -p ${KEYS_DIR}/liteserver.pub -a 127.0.0.1:3031"

ACCOUNT_INFO=`$CALL_LT -rc "getaccount ${ACCOUNT}" -t "3" -rc "quit" 2>/dev/null `

ACC_STATUS=`echo "$ACCOUNT_INFO" | grep "state:" | awk -F "(" '{ print $2 }'`
AMOUNT=`echo "$ACCOUNT_INFO" |grep "account balance" | tr -d "ng"|awk '{print $4}'`
LAST_TR_TIME=`echo "$ACCOUNT_INFO" | grep "last_paid" | gawk -F ":" '{print strftime("%Y-%m-%d %H:%M:%S", $5)}'`

echo
echo "Account: $ACCOUNT"
echo "Time Now: $(date  +'%Y-%m-%d %H:%M:%S')"
echo "Status: $ACC_STATUS"
echo "Has balance : $((AMOUNT/1000000000)) tokens"
echo "Last operation time: $LAST_TR_TIME"
# "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "Current balance: $((AMOUNT/1000000000))" 2>&1 > /dev/null
echo "=================================================================================================="


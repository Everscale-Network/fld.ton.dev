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
OS_SYSTEM=`uname`
if [[ "$OS_SYSTEM" == "Linux" ]];then
    CALL_BC="bc"
else
    CALL_BC="bc -l"
fi

trap not_found EXIT

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

ACCOUNT=$1
if [[ -z $ACCOUNT ]];then
    MY_ACCOUNT=`cat "${KEYS_DIR}/${HOSTNAME}.addr"`
    if [[ -z $MY_ACCOUNT ]];then
        echo " Can't find ${KEYS_DIR}/${HOSTNAME}.addr"
        exit 1
    else
        ACCOUNT=$MY_ACCOUNT
    fi
else
    acc_fmt="$(echo "$ACCOUNT" |  awk -F ':' '{print $2}')"
    [[ -z $acc_fmt ]] && ACCOUNT=`cat "${KEYS_DIR}/${ACCOUNT}.addr"`
fi

ACCOUNT_INFO=`$CALL_LC -rc "getaccount ${ACCOUNT}" -rc "quit" 2>/dev/null`

ACC_STATUS=`echo "$ACCOUNT_INFO" | grep 'state:'|tr -d ')'|tr -d '('|cut -d ':' -f 2`
AMOUNT=`echo "$ACCOUNT_INFO" |grep "account balance" | tr -d "ng"|awk '{print $4}'`
LAST_TR_TIME=`echo "$ACCOUNT_INFO" | grep "last_paid" | gawk -F ":" '{print strftime("%Y-%m-%d %H:%M:%S", $5)}'`

echo
echo "Account: $ACCOUNT"
echo "Time Now: $(date  +'%Y-%m-%d %H:%M:%S')"
echo "Status: $ACC_STATUS"
echo "Has balance : $(echo "scale=3; $((AMOUNT)) / 1000000000" | $CALL_BC) tokens"
echo "Last operation time: $LAST_TR_TIME"
# "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "Current balance: $((AMOUNT/1000000000))" 2>&1 > /dev/null
echo "=================================================================================================="
exit 0

#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${SCRIPT_DIR}/env.sh"

function TD_unix2human() {
    local OS_SYSTEM=`uname -s`
    local ival="$(echo ${1}|tr -d '"')"
    if [[ "$OS_SYSTEM" == "Linux" ]];then
        echo "$(date  +'%F %T %Z' -d @$ival)"
    else
        echo "$(date -r $ival +'%F %T %Z')"
    fi
}

VestRound=`tonos-cli run $(cat $KEYS_DIR/depool.addr) getParticipantInfo "{\"addr\":\"$(cat $KEYS_DIR/$(hostname -s).addr)\"}" --abi $DSCs_DIR/DePool.abi.json| sed -e '1,/Succeeded./d'|sed 's/Result: //'|jq '[.vestings[]]|.[0]'`
LWT=`echo "$VestRound"|jq -r '.lastWithdrawalTime'`
WPer=`echo "$VestRound"|jq -r '.withdrawalPeriod'`
Wval=`echo "$VestRound"|jq -r '.withdrawalValue'`
Value=`echo "$VestRound"|jq -r '.withdrawalValue'`

echo "Your will receive vesting total payment $((Value * 2 / 1000000000)) at $(TD_unix2human $((LWT + WPer))), divided equally into two rounds."

exit 0

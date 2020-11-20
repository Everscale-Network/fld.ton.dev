#!/bin/bash -eE

# (C) Sergey Tyurin  2020-09-20 13:00:00

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
# You have to have installed :
#   'xxd' - is a part of vim-commons ( [apt/dnf/pkg] install vim[-common] )
#   'jq'
#   'tvm_linker' compiled binary from https://github.com/tonlabs/TVM-linker.git to $HOME/bin (must be in $PATH)
#   'lite-client'                                               
# ------------------------------------------------------------------------
# Script assumes that: 
#   - all keypairs are in ${KEYS_DIR} folder
#   - Tik account is SafeMultisigWallet with one custodian
#   - Tik.addr - file with addr of Tik account
#   - Tik.keys.json - keypair of Tik account
#   - Depool address is in depool.addr file
#   - If you want to tik other depool address, the address should be in file <depool name>.addr in KEYS_DIR
#     and usage will ./dtik_depool.sh <depool name>
# ------------------------------------------------------------------------

# set -x

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

###################
TIMEDIFF_MAX=100
SLEEP_TIMEOUT=10
SEND_ATTEMPTS=10
###################


Depool_addr=`cat ${KEYS_DIR}/depool.addr`
#Helper_addr=`cat ${KEYS_DIR}/helper.addr`
#Proxy0_addr=`cat ${KEYS_DIR}/proxy0.addr`
#Proxy1_addr=`cat ${KEYS_DIR}/proxy1.addr`
Validator_addr=`cat ${KEYS_DIR}/${HOSTNAME}.addr`
Tik_addr=`cat ${KEYS_DIR}/Tik.addr`
Tik_Keys_File="${KEYS_DIR}/Tik.keys.json"

Work_Chain=`echo "${Tik_addr}" | cut -d ':' -f 1`

old_depool_name=$1
[[ ! -z $old_depool_name ]] && old_depool_addr=$(cat ${KEYS_DIR}/${old_depool_name}.addr)
Depool_addr=${old_depool_addr:=$Depool_addr}

ELECTIONS_WORK_DIR="${KEYS_DIR}/elections"
SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"
CALL_LC="${TON_BUILD_DIR}/lite-client/lite-client -p ${KEYS_DIR}/liteserver.pub -a 127.0.0.1:3031 -t 5"
CALL_TL="$HOME/bin/tvm_linker"

Tik_Payload="te6ccgEBAQEABgAACCiAmCM="
NANOSTAKE=$((1 * 1000000000))

##############################################################################
# prepare user signature
tik_acc_addr=`echo "${Tik_addr}" | cut -d ':' -f 2`
touch $tik_acc_addr
tik_public=`cat $Tik_Keys_File | jq ".public" | tr -d '"'`
tik_secret=`cat $Tik_Keys_File | jq ".secret" | tr -d '"'`
if [[ -z $tik_public ]] || [[ -z $tik_secret ]];then
    echo "###-ERROR: Can't find Tik public and/or secret key!"
    exit 1
fi
echo "${tik_secret}${tik_public}" > ${KEYS_DIR}/tik.keys.txt
rm -f ${KEYS_DIR}/tik.keys.bin
xxd -r -p ${KEYS_DIR}/tik.keys.txt ${KEYS_DIR}/tik.keys.bin

##############################################################################
# make boc for lite-client
echo "INFO: Make boc for lite-client ..."
TVM_OUTPUT=$($CALL_TL message $tik_acc_addr \
    -a ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
    -m submitTransaction \
    -p "{\"dest\":\"$Depool_addr\",\"value\":$NANOSTAKE,\"bounce\":true,\"allBalance\":false,\"payload\":\"$Tik_Payload\"}" \
    -w $Work_Chain --setkey ${KEYS_DIR}/tik.keys.bin | tee ${ELECTIONS_WORK_DIR}/TVM_linker-tikquery.log)

if [[ -z $(echo $TVM_OUTPUT | grep "boc file created") ]];then
    echo "###-ERROR: TVM linker CANNOT create boc file!!! Can't continue."
    exit 2
fi

mv "$(echo "$tik_acc_addr"| cut -c 1-8)-msg-body.boc" "${ELECTIONS_WORK_DIR}/tik-msg.boc"
echo "INFO: Make boc for lite-client ... DONE"
##############################################################################
###############  Send query by lite-client ###################################
##############################################################################
Last_Trans_lt=$($CALL_LC -rc "getaccount ${Depool_addr}" -t "3" -rc "quit" 2>/dev/null |grep 'last transaction lt'|awk '{print $5}')

echo "INFO: Send query to Depool by lite-client ..."

Attempts_to_send=$SEND_ATTEMPTS
while [[ $Attempts_to_send -gt 0 ]]; do

    $CALL_LC -rc "sendfile ${ELECTIONS_WORK_DIR}/tik-msg.boc" -rc 'quit' &> ${ELECTIONS_WORK_DIR}/tik-req-result.log
    vr_result=`cat ${ELECTIONS_WORK_DIR}/tik-req-result.log | grep "external message status is 1"`

    if [[ -z $vr_result ]]; then
        echo "###-ERROR: Send message for Tik FAILED!!!"
    fi

    echo "INFO: Tik-tok transaction to depool submitted!"

    echo "INFO: Check depool cranked ..."
    sleep $SLEEP_TIMEOUT
    Curr_Trans_lt=$($CALL_LC -rc "getaccount ${Depool_addr}" -t "3" -rc "quit" 2>/dev/null |grep 'last transaction lt'|awk '{print $5}')
    if [[ $Curr_Trans_lt == $Last_Trans_lt ]];then
        echo "Attempt # $((SEND_ATTEMPTS + 1 - Attempts_to_send))/$SEND_ATTEMPTS"
        echo "+++-WARNING: Depool does not crank up .. Repeat sending.."
        Attempts_to_send=$((Attempts_to_send - 1))
    else
        echo "INFO: Depool tiked SUCCESSFULLY!"
        break
    fi
done

if [[ Attempts_to_send -eq 0   ]];then
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "ALARM!!! Can't TIK Depool!!!" 2>&1 > /dev/null
    echo "###-=ERROR: ALARM!!! Depool DOES NOT CRANKED UP!!!"
    echo "INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"
    exit 3
fi

date +"INFO: %F %T Depool Tiked"
echo "INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"

trap - EXIT
exit 0


#!/bin/bash

function tr_usage(){
echo
echo " use: transfer_amount.sh <SRC> <DST> <AMOUNT> [new]"
echo " new - for transfer to not activated account (for creation)"
echo
exit 0
}

[[ $# -le 2 ]] && tr_usage

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
source "${HOME}/net.ton.dev/scripts/env.sh"

SRC_NAME=$1
DST_NAME=$2
TRANSF_AMOUNT="$3"
NEW_ACC=$4
[[ -z $TRANSF_AMOUNT ]] && tr_usage

NANO_AMOUNT=`${UTILS_DIR}/tonos-cli convert tokens $TRANSF_AMOUNT| grep "[0-9]"`

echo "Nanotokens to transfer: $NANO_AMOUNT"

if [[ "$NEW_ACC" == "new" ]];then
    BOUNCE="false"
else
    BOUNCE="true"
fi

SRC_ACCOUNT=`cat ${KEYS_DIR}/${SRC_NAME}.addr`
DST_ACCOUNT=`cat ${KEYS_DIR}/${DST_NAME}.addr`
SRC_KEY_FILE="${KEYS_DIR}/${1}.keys.json"

echo "Check SRC $SRC_NAME account.."
SRC_BALANCE_INFO=`${UTILS_DIR}/tonos-cli account $SRC_ACCOUNT || echo "ERROR get balance" && exit 0`
SRC_AMOUNT=`echo "$SRC_BALANCE_INFO" | grep balance | awk '{ print $2 }'`
SRC_TIME=`echo "$SRC_BALANCE_INFO" | grep last_paid | gawk '{ print strftime("%Y-%m-%d %H:%M:%S", $2)}'`

echo "Check DST $DST_NAME account.."
DST_BALANCE_INFO=`${UTILS_DIR}/tonos-cli account $DST_ACCOUNT || echo "ERROR get balance" && exit 0`
DST_AMOUNT=`echo "$DST_BALANCE_INFO" | grep balance | awk '{ print $2 }'`
DST_TIME=`echo "$DST_BALANCE_INFO" | grep last_paid | gawk '{ print strftime("%Y-%m-%d %H:%M:%S", $2)}'`

echo "TRANFER FROM ${SRC_NAME} :"
echo "SRC Account: $SRC_ACCOUNT"
echo "Has balance : $((SRC_AMOUNT/1000000000)) tokens"
echo "Last operation time: $SRC_TIME"
echo
echo "TRANFER TO ${DST_NAME} :"
echo "DST Account: $DST_ACCOUNT"
echo "Has balance : $((DST_AMOUNT/1000000000)) tokens"
echo "Last operation time: $DST_TIME"
echo
echo "Transferring $TRANSF_AMOUNT ($NANO_AMOUNT) from ${SRC_NAME} to ${DST_NAME} ..." 

read -p "### CHECK INFO TWICE!!! Is this a right tranfer?  (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        echo "Processing....."
    ;;
    * )
        echo "Cancelled."
        exit 1
    ;;
esac

# ==========================================================================
TONOS_CLI_SEND_ATTEMPTS="10"

for i in $(seq ${TONOS_CLI_SEND_ATTEMPTS}); do
    echo "INFO: tonos-cli submitTransaction attempt #${i}..."
    if ! "${UTILS_DIR}/tonos-cli" call "${SRC_ACCOUNT}" submitTransaction \
        "{\"dest\":\"${DST_ACCOUNT}\",\"value\":\"${NANO_AMOUNT}\",\"bounce\":$BOUNCE,\"allBalance\":false,\"payload\":\"\"}" \
        --abi "${CONFIGS_DIR}/SafeMultisigWallet.abi.json" \
        --sign "${SRC_KEY_FILE}"; then
        echo "INFO: tonos-cli submitTransaction attempt #${i}... FAIL"
    else
        echo "INFO: tonos-cli submitTransaction attempt #${i}... PASS"
        break
    fi
    sleep 5s
done
# ==========================================================================

echo "Check SRC $SRC_NAME account.."
SRC_BALANCE_INFO=`${UTILS_DIR}/tonos-cli account $SRC_ACCOUNT || echo "ERROR get balance" && exit 0`
SRC_AMOUNT=`echo "$SRC_BALANCE_INFO" | grep balance | awk '{ print $2 }'`
SRC_TIME=`echo "$SRC_BALANCE_INFO" | grep last_paid | gawk '{ print strftime("%Y-%m-%d %H:%M:%S", $2)}'`

echo "Check DST $DST_NAME account.."
DST_BALANCE_INFO=`${UTILS_DIR}/tonos-cli account $DST_ACCOUNT || echo "ERROR get balance" && exit 0`
DST_AMOUNT=`echo "$DST_BALANCE_INFO" | grep balance | awk '{ print $2 }'`
DST_TIME=`echo "$DST_BALANCE_INFO" | grep last_paid | gawk '{ print strftime("%Y-%m-%d %H:%M:%S", $2)}'`

echo
echo "${SRC_NAME} Account: $SRC_ACCOUNT"
echo "Has balance : $((SRC_AMOUNT/1000000000)) tokens"
echo "Last operation time: $SRC_TIME"
echo

echo
echo "${DST_NAME} Account: $DST_ACCOUNT"
echo "Has balance : $((DST_AMOUNT/1000000000)) tokens"
echo "Last operation time: $DST_TIME"
echo



exit 0


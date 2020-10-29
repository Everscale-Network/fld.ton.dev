#!/bin/bash


# tonos-cli deploy <MultisigWallet.tvc> '{"owners":["0x...", ...],"reqConfirms":N}' --abi <MultisigWallet.abi.json> --sign <deploy_seed_or_keyfile> --wc <workchain_id>

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

KEY_FILES_DIR="$HOME/DMSKeys"

CALL_LC="${TON_BUILD_DIR}/lite-client/lite-client -p ${KEYS_DIR}/liteserver.pub -a 127.0.0.1:3031 -t 5"

WALL_ADDR=`cat $KEY_FILES_DIR/${HOSTNAME}.addr`
if [[ -z $WALL_ADDR ]];then
    echo
    echo "###-ERROR: Cannot find wallet address in file $KEY_FILES_DIR/${HOSTNAME}.addr"
    echo
    exit 1
fi
echo "Wallet for deploy : $WALL_ADDR"

#=================================================
# Check wallet balance
ACCOUNT_INFO=`$CALL_LC -rc "getaccount ${WALL_ADDR}" -t "3" -rc "quit" 2>/dev/null `
AMOUNT=`echo "$ACCOUNT_INFO" |grep "account balance" | tr -d "ng"|awk '{print $4}'`
ACTUAL_BALANCE=$((AMOUNT / 1000000000))
if [[ $ACTUAL_BALANCE -lt 3 ]];then
    echo "###-ERROR: You haven't enough tokens to deploy wallet. Current balance: $ACTUAL_BALANCE. You need 3 at least. Exit."
    exit 1
fi
#=================================================
# Check numbers of custodians

MSIGs_List=`ls $KEY_FILES_DIR/msig* | tr "\n" " "`
Cust_QTY=`echo $MSIGs_List | awk '{print NF}'`
if [[ $Cust_QTY -lt 3 ]];then
    echo
    echo "###-ERROR: You have to have at least 3 custodians. Found $Cust_QTY only."
    echo
    exit 1
fi
echo "Number of custodians keypairs: $Cust_QTY"

#=================================================
# Read all pubkeys and make a string
Custodians_PubKeys=""
for (( i=1; i<=$Cust_QTY; i++))
do
    PubKey="0x$(cat $KEY_FILES_DIR/msig${i}.keys.json | jq '.public'| tr -d '\"')"
    Custodians_PubKeys+="\"${PubKey}\","
done

Custodians_PubKeys=${Custodians_PubKeys::-1}
echo "Current Custodians_PubKeys: '$Custodians_PubKeys'"

#=================================================
# Deploy wallet

${UTILS_DIR}/tonos-cli deploy \
${CONFIGS_DIR}/SafeMultisigWallet.tvc \
"{\"owners\":[$Custodians_PubKeys],\"reqConfirms\":$Cust_QTY}" \
--abi ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
--sign $KEY_FILES_DIR/msig1.keys.json \
--wc 0 | tee $KEY_FILES_DIR/deploy_wallet.log

exit 0


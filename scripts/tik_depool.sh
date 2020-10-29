#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

Depool_addr=`cat ${KEYS_DIR}/depool.addr`
Helper_addr=`cat ${KEYS_DIR}/helper.addr`
Proxy0_addr=`cat ${KEYS_DIR}/proxy0.addr`
Proxy1_addr=`cat ${KEYS_DIR}/proxy1.addr`
Validator_addr=`cat ${KEYS_DIR}/${HOSTNAME}.addr`
Tik_addr=`cat ${KEYS_DIR}/Tik.addr`
Work_Chain=`echo "${Tik_addr}" | cut -d ':' -f 1`

old_depool_name=$1
[[ ! -z $old_depool_name ]] && old_depool_addr=$(cat ${KEYS_DIR}/${old_depool_name}.addr)
Depool_addr=${old_depool_addr:=$Depool_addr}

SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"

# tonos-cli call <адрес_мультисига> sendTransaction '{"dest":"<адрес_депула>","value":1000000000,"bounce":true,"flags":3,"payload":"te6ccgEBAQEABgAACCiAmCM="}' --abi SafeMultisigWallet.abi.json --sign msig.keys.json
#                                                                                        1000000000 = 1 token
tonos-cli call "$Tik_addr" sendTransaction "{\"dest\":\"$Depool_addr\",\"value\":1000000000,\"bounce\":true,\"flags\":3,\"payload\":\"te6ccgEBAQEABgAACCiAmCM=\"}" \
    --abi ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
    --sign ${KEYS_DIR}/Tik.keys.json

exit 0

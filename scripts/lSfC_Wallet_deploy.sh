#!/bin/bash

# tonos-cli deploy <MultisigWallet.tvc> '{"owners":["0x...", ...],"reqConfirms":N}' --abi <MultisigWallet.abi.json> --sign <deploy_seed_or_keyfile> --wc <workchain_id>

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`

echo "cd to $SCRIPT_DIR"
cd $SCRIPT_DIR
. "${SCRIPT_DIR}/env.sh"

WALL_NAME=$1
MSIG_JSON=${WALL_NAME:-"msig"}
WALL_FILE=${WALL_NAME:-$HOSTNAME}

SafeC_Wallet_ABI="$SCRIPT_DIR/../ton-labs-contracts/solidity/safemultisig/SafeMultisigWallet.abi.json"

echo "MSIG_JSON: $MSIG_JSON"

OWN_PUB_KEY=0x`cat ${KEYS_DIR}/${MSIG_JSON}.keys.json | jq ".public" | tr -d '"'`
WALL_ADDR=`cat ${KEYS_DIR}/${WALL_FILE}.addr`

[[ "$OWN_PUB_KEY" == "0x" ]] && echo "### - ERROR: Empty Public key! Exit." && exit 1

Work_Chain=`echo "${WALL_ADDR}" | cut -d ':' -f 1`

echo
echo "Deploy wallet: ${WALL_ADDR}"
echo "Public key:    ${OWN_PUB_KEY}"
echo "WorkChain:     ${Work_Chain}"
echo

tonos-cli message $WALL_ADDR constructor \
    "{\"owners\":[\"$OWN_PUB_KEY\"],\"reqConfirms\":1}" \
    --abi ${SafeC_Wallet_ABI} \
    --sign ${KEYS_DIR}/${MSIG_JSON}.keys.json --raw --output ${WALL_FILE}-deploy-msg.boc

$CALL_LC -rc "sendfile ${WALL_FILE}-deploy-msg.boc" -rc 'quit' &> ${WALL_FILE}-deploy-result.log

exit 0


#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

ELECTIONS_WORK_DIR="${KEYS_DIR}/elections"
[[ ! -d ${ELECTIONS_WORK_DIR} ]] && mkdir -p ${ELECTIONS_WORK_DIR}
chmod +x ${ELECTIONS_WORK_DIR}

SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"

# tonos-cli deploy DePool.tvc '{"minRoundStake":*number*,"proxy0":"<proxy0Address>","proxy1":"<proxy1Address>","validatorWallet":"<validatorWalletAddress>","minStake":*number*}' --abi DePool.abi.json --sign depool.json

Depool_addr=`cat ${KEYS_DIR}/depool.addr`
Proxy0_addr=`cat ${KEYS_DIR}/proxy0.addr`
Proxy1_addr=`cat ${KEYS_DIR}/proxy1.addr`
Validator_addr=`cat ${KEYS_DIR}/${HOSTNAME}.addr`

echo "Depool_addr: $Depool_addr"

# minimal total stake (in nanotons) that has to be accumulated in the DePool to participate in elections
# For participants of the DePool Contest, this value should be no more than half of the stake given to them for the contest.
MinRoundStake=$((20000 * 1000000000))

# minimum stake (in nanotons) that DePool accepts from participantsю It's recommended to set it not less than 10 Tons.
MinStake=$((100 * 1000000000))

#tonos-cli deploy ${SCs_DIR}/DePoolProxy.tvc "{\"depool\":\"$Depool_addr\"}" --abi ${SCs_DIR}/DePoolProxy.abi.json --sign ${KEYS_DIR}/proxy0.json --wc -1 | tee ${ELECTIONS_WORK_DIR}/proxy0-deploy.log
#tonos-cli deploy ${SCs_DIR}/DePoolProxy.tvc "{\"depool\":\"$Depool_addr\"}" --abi ${SCs_DIR}/DePoolProxy.abi.json --sign ${KEYS_DIR}/proxy1.json --wc -1 | tee ${ELECTIONS_WORK_DIR}/proxy1-deploy.log

tonos-cli deploy ${SCs_DIR}/DePool.tvc \
    "{\"minRoundStake\":$MinRoundStake,\"proxy0\":\"$Proxy0_addr\",\"proxy1\":\"$Proxy1_addr\",\"validatorWallet\":\"$Validator_addr\",\"minStake\":$MinStake}" \
    --abi ${SCs_DIR}/DePool.abi.json \
    --sign ${KEYS_DIR}/depool.json --wc 0 | tee ${ELECTIONS_WORK_DIR}/depool-deploy.log

tonos-cli deploy ${SCs_DIR}/DePoolHelper.tvc "{\"pool\":\"$Depool_addr\"}" \
    --abi ${SCs_DIR}/DePoolHelper.abi.json \
    --sign ${KEYS_DIR}/helper.json --wc 0 | tee ${ELECTIONS_WORK_DIR}/helper-deploy.log

exit 0

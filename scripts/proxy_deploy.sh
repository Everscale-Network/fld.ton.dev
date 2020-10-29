#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

ELECTIONS_WORK_DIR="${KEYS_DIR}/elections"
[[ ! -d ${ELECTIONS_WORK_DIR} ]] && mkdir -p ${ELECTIONS_WORK_DIR}
chmod +x ${ELECTIONS_WORK_DIR}

SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"

# tonos-cli deploy DePoolProxy.tvc '{"depool":"<DePoolAddress>"}' --abi DePoolProxy.abi.json --sign proxy0.json --wc -1

Depool_addr=`cat ${KEYS_DIR}/depool.addr`

echo "Depool_addr: $Depool_addr"

tonos-cli deploy ${SCs_DIR}/DePoolProxy.tvc "{\"depool\":\"$Depool_addr\"}" --abi ${SCs_DIR}/DePoolProxy.abi.json --sign ${KEYS_DIR}/proxy0.json --wc -1 | tee ${ELECTIONS_WORK_DIR}/proxy0-deploy.log
tonos-cli deploy ${SCs_DIR}/DePoolProxy.tvc "{\"depool\":\"$Depool_addr\"}" --abi ${SCs_DIR}/DePoolProxy.abi.json --sign ${KEYS_DIR}/proxy1.json --wc -1 | tee ${ELECTIONS_WORK_DIR}/proxy1-deploy.log


exit 0

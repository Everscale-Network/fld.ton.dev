#!/bin/bash 

export NETWORK_TYPE="fld.ton.dev"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
export INSTALL_DEPENDENCIES="yes"
export NET_TON_DEV_SRC_TOP_DIR=$(cd "${SCRIPT_DIR}/../" && pwd -P)
export TON_GITHUB_REPO="https://github.com/FreeTON-Network/FreeTON-Node.git"
export TON_STABLE_GITHUB_COMMIT_ID="cdfd7ce654bf6afe4e8de962c7f68abe1011b8a0"
export TON_SRC_DIR="${NET_TON_DEV_SRC_TOP_DIR}/ton"
export TON_BUILD_DIR="${TON_SRC_DIR}/build"
export TONOS_CLI_SRC_DIR="${NET_TON_DEV_SRC_TOP_DIR}/tonos-cli"
export UTILS_DIR="${TON_BUILD_DIR}/utils"

export TON_WORK_DIR="/var/ton-work"
export TON_LOG_DIR="/var/ton-work"
export KEYS_DIR="$HOME/ton-keys"
export ELECTIONS_WORK_DIR="${KEYS_DIR}/elections"

export CONFIGS_DIR="${NET_TON_DEV_SRC_TOP_DIR}/configs"
export ADNL_PORT="30310"
export HOSTNAME=$(hostname -s)
export VALIDATOR_NAME="$HOSTNAME"
export PATH="${UTILS_DIR}:$PATH"
export LITESERVER_IP="127.0.0.1"
export LITESERVER_PORT="3031"
export ENGINE_ADDITIONAL_PARAMS=""

export CALL_LC="${TON_BUILD_DIR}/lite-client/lite-client -p ${KEYS_DIR}/liteserver.pub -a 127.0.0.1:3031 -t 5"
export CALL_VE="${TON_BUILD_DIR}/validator-engine/validator-engine"
export CALL_VC="${TON_BUILD_DIR}/validator-engine-console/validator-engine-console -k ${KEYS_DIR}/client -p ${KEYS_DIR}/server.pub -a 127.0.0.1:3030 -t 5"
export CALL_TL="$HOME/bin/tvm_linker"
export CALL_FT="${TON_BUILD_DIR}/crypto/fift -I ${TON_SRC_DIR}/crypto/fift/lib:${TON_SRC_DIR}/crypto/smartcont"

export SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/safemultisig"
export DSCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"

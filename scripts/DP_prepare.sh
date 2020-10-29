#!/bin/bash -eE

# (C) Sergey Tyurin  2020-08-18 19:00:00

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

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

SCs_DIR="$NET_TON_DEV_SRC_TOP_DIR/ton-labs-contracts/solidity/depool"

KEY_FILES_DIR="$HOME/DPKeys"
[[ ! -d $KEY_FILES_DIR ]] && mkdir $KEY_FILES_DIR

cd $KEY_FILES_DIR



[[ ! -f proxy0_seed.txt ]] && tonos-cli genphrase > proxy0_seed.txt
[[ ! -f proxy1_seed.txt ]] && tonos-cli genphrase > proxy1_seed.txt
[[ ! -f depool_seed.txt ]] && tonos-cli genphrase > depool_seed.txt
[[ ! -f helper_seed.txt ]] && tonos-cli genphrase > helper_seed.txt

tonos-cli getkeypair proxy0.json "$(cat proxy0_seed.txt | grep "Seed phrase:" | cut -d' ' -f3-14)" && cp -f proxy0.json proxy0.keys.json
tonos-cli getkeypair proxy1.json "$(cat proxy1_seed.txt | grep "Seed phrase:" | cut -d' ' -f3-14)" && cp -f proxy1.json proxy1.keys.json
tonos-cli getkeypair depool.json "$(cat depool_seed.txt | grep "Seed phrase:" | cut -d' ' -f3-14)" && cp -f depool.json depool.keys.json
tonos-cli getkeypair helper.json "$(cat helper_seed.txt | grep "Seed phrase:" | cut -d' ' -f3-14)" && cp -f helper.json helper.keys.json

tonos-cli genaddr $SCs_DIR/DePoolProxy.tvc  $SCs_DIR/DePoolProxy.abi.json  --setkey proxy0.json --wc -1 | tee proxy0.addr-card.txt | grep "Raw address:" | awk '{print $3}' | tee proxy0.addr
tonos-cli genaddr $SCs_DIR/DePoolProxy.tvc  $SCs_DIR/DePoolProxy.abi.json  --setkey proxy1.json --wc -1 | tee proxy1.addr-card.txt | grep "Raw address:" | awk '{print $3}' | tee proxy1.addr
tonos-cli genaddr $SCs_DIR/DePool.tvc       $SCs_DIR/DePool.abi.json       --setkey depool.json --wc 0  | tee depool.addr-card.txt | grep "Raw address:" | awk '{print $3}' | tee depool.addr
tonos-cli genaddr $SCs_DIR/DePoolHelper.tvc $SCs_DIR/DePoolHelper.abi.json --setkey helper.json --wc 0  | tee helper.addr-card.txt | grep "Raw address:" | awk '{print $3}' | tee helper.addr

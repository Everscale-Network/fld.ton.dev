#!/bin/bash -eE

# (C) Sergey Tyurin  2020-08-17 10:00:00

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

KEY_FILES_DIR="$HOME/MSKeys"
[[ ! -d $KEY_FILES_DIR ]] && mkdir $KEY_FILES_DIR

CUSTODIANS=$1

if [[ ! $# -eq 1 ]];then
    echo
    echo "USAGE: ./Prep-3msig.sh <num of custodians>"
    echo "<num of custodians> must greater 0 or less 32"
    echo "All keys will be saved in $HOME/MSKeys"
    echo
    exit 1
fi

if [[ $CUSTODIANS -lt 1 ]] || [[ $CUSTODIANS -gt 31 ]];then
    echo
    echo "<num of custodians> must greater 0 or less 32 (1-31)"
    echo
    exit 1
fi

#=======================================================================================
for i in `seq -s " " "${CUSTODIANS}"`
do
    echo "$i"

# generate or read seed phrases
[[ ! -f $KEY_FILES_DIR/seed${i}.txt ]] && SeedPhrase=`${UTILS_DIR}/tonos-cli genphrase | grep "Seed phrase:" | cut -d' ' -f3-14 | tee $KEY_FILES_DIR/seed${i}.txt`
[[ -f $KEY_FILES_DIR/seed${i}.txt ]] && SeedPhrase=`cat $KEY_FILES_DIR/seed${i}.txt`

# generate public key
PubKey=`${UTILS_DIR}/tonos-cli genpubkey "$SeedPhrase${i}" | tee $KEY_FILES_DIR/PubKeyCard${i}.txt | grep "Public key:" | awk '{print $3}' | tee $KEY_FILES_DIR/pub${i}.key`
echo "PubKey${i}: $PubKey"

# generate pub/sec keypair
${UTILS_DIR}/tonos-cli getkeypair "$KEY_FILES_DIR/msig${i}.keys.json" "$SeedPhrase${i}" &> /dev/null
done
#=======================================================================================

# generate safe multisignature wallet address
WalletAddress=`${UTILS_DIR}/tonos-cli genaddr \
		${CONFIGS_DIR}/SafeMultisigWallet.tvc \
		${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
		--setkey "$KEY_FILES_DIR/msig1.keys.json" --wc "-1" \
		| tee  $KEY_FILES_DIR/${HOSTNAME}_addr-card.txt \
		| grep "Raw address:" | awk '{print $3}' \
		| tee $KEY_FILES_DIR/${HOSTNAME}.addr`

echo "Wallet Address: $WalletAddress"
echo
echo "All keys saved in $HOME/MSKeys"
echo
exit 0


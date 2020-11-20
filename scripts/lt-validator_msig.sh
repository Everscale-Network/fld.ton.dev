#!/bin/bash

# (C) Sergey Tyurin  2020-08-08 12:00:00

# You have to have installed :
#   'xxd' - is a part of vim-commons ( [apt/dnf/pkg] install vim[-common] )
#   'jq'
#   'bc' for Linux
#   'dc' for FreeBSD
#   'tvm_linker' compiled binary from https://github.com/tonlabs/TVM-linker.git to $HOME/bin (must be in $PATH)
#   'lite-client'                                               
#   'validator-engine-console'
#   'fift'

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

set -o pipefail

if [ "$DEBUG" = "yes" ]; then
    set -x
fi

###############
TIMEDIFF_MAX=100
###############

echo "INFO: $(basename "$0") BEGIN $(date +%s) / $(date)"

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

#=================================================
hex2dec() {
    OS_SYSTEM=`uname`
    ival="${1^^}"
    ob=${2:-10}
    ib=${3:-16}
    if [[ "$OS_SYSTEM" == "Linux" ]];then
        export BC_LINE_LENGTH=0
        # set obase first before ibase -- or weird things happen.
        printf "obase=%d; ibase=%d; %s\n" $ob $ib $ival | bc
    else
        dc -e "${ib}i ${ival} p" | tr -d "\\" | tr -d "\n"
    fi
}
#=================================================
# Test binaries
if [[ -z $($HOME/bin/tvm_linker -V | grep "TVM linker") ]];then
    echo "###-ERROR: TVM linker not installed in PATH"
    exit 1
fi

if [[ -z $(xxd -v 2>&1 | grep "Juergen Weigert") ]];then
    echo "###-ERROR: 'xxd' not installed in PATH"
    exit 1
fi

#=================================================
# 
STAKE="$1"

if [ -z "${STAKE}" ]; then
    echo "ERROR: STAKE (in tokens) is not specified"
    echo "Usage: $(basename "$0") <STAKE>"
    exit 1
fi

MAX_FACTOR=${MAX_FACTOR:-3}

CALL_LC="${TON_BUILD_DIR}/lite-client/lite-client -p ${KEYS_DIR}/liteserver.pub -a 127.0.0.1:3031 -t 5"
CALL_VC="${TON_BUILD_DIR}/validator-engine-console/validator-engine-console -k ${KEYS_DIR}/client -p ${KEYS_DIR}/server.pub -a 127.0.0.1:3030 -t 5"
CALL_FIFT="${TON_BUILD_DIR}/crypto/fift -I ${TON_SRC_DIR}/crypto/fift/lib:${TON_SRC_DIR}/crypto/smartcont"

#=================================================
MSIG_ADDR=`cat "${KEYS_DIR}/${VALIDATOR_NAME}.addr"`
if [[ -z $MSIG_ADDR ]];then
    echo "###-ERROR: Can't find validator account address!"
    exit 1
fi

val_acc_addr=`echo "${MSIG_ADDR}" | cut -d ':' -f 2`
echo "INFO: MSIG_ADDR = ${MSIG_ADDR} / $val_acc_addr"

ELECTIONS_WORK_DIR="${KEYS_DIR}/elections"
[[ ! -d ${ELECTIONS_WORK_DIR} ]] && mkdir -p ${ELECTIONS_WORK_DIR}
chmod +x ${ELECTIONS_WORK_DIR}
##############################################################################
# prepare user signature
val_acc_addr=`echo "${MSIG_ADDR}" | cut -d ':' -f 2`
touch $val_acc_addr
msig_public=`cat ${KEYS_DIR}/msig.keys.json | jq ".public" | tr -d '"'`
msig_secret=`cat ${KEYS_DIR}/msig.keys.json | jq ".secret" | tr -d '"'`
if [[ -z $msig_public ]] || [[ -z $msig_secret ]];then
    echo "###-ERROR: Can't find validator public and/or secret key!"
    exit 1
fi
echo "${msig_secret}${msig_public}" > ${KEYS_DIR}/msig.keys.txt
rm -f ${KEYS_DIR}/msig.keys.bin
xxd -r -p ${KEYS_DIR}/msig.keys.txt ${KEYS_DIR}/msig.keys.bin

##############################################################################
# Check node sync
trap 'echo VC EXIT' EXIT
VEC_OUTPUT=`$CALL_VC -c "getstats" -c "quit"`
trap - EXIT

CURR_TD_NOW=`echo "${VEC_OUTPUT}" | grep unixtime | awk '{print $2}'`
CHAIN_TD=`echo "${VEC_OUTPUT}" | grep masterchainblocktime | awk '{print $2}'`
TIME_DIFF=$((CURR_TD_NOW - CHAIN_TD))
if [[ $TIME_DIFF -gt $TIMEDIFF_MAX ]];then
    echo "###-ERROR: Your node is not synced. Wait until full sync (<$TIMEDIFF_MAX) Current timediff: $TIME_DIFF"
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "###-ERROR: Your node is not synced. Wait until full sync (<$TIMEDIFF_MAX) Current timediff: $TIME_DIFF" 2>&1 > /dev/null
    exit 1
fi
echo "INFO: Current TimeDiff: $TIME_DIFF"

##############################################################################
# get elector address
trap 'echo LC TIMEOUT EXIT' EXIT
elector_addr=`$CALL_LC -rc "getconfig 1" -rc "quit" 2>/dev/null | grep -i 'ConfigParam(1)' | awk '{print substr($4,15,64)}'`
trap - EXIT
elector_addr=`echo "-1:"$elector_addr | tee ${ELECTIONS_WORK_DIR}/elector-addr-base64`
echo "INFO: Elector Address: $elector_addr"

##############################################################################
# get elections ID
trap 'echo LC TIMEOUT EXIT' EXIT
election_id=`$CALL_LC -rc "runmethod $elector_addr active_election_id" -rc "quit" 2>/dev/null | grep "result:" | awk '{print $3}' | tee ${ELECTIONS_WORK_DIR}/election-id`
trap - EXIT
echo "INFO: Election ID: $election_id"

if [[ ! -z $election_id ]] && [[ ! -f ${ELECTIONS_WORK_DIR}/$election_id ]];then
  touch ${ELECTIONS_WORK_DIR}/$election_id
  echo "Election ID: $election_id" >> ${ELECTIONS_WORK_DIR}/$election_id
  echo "Elector address: $elector_addr" >> ${ELECTIONS_WORK_DIR}/$election_id
fi
##############################################################################
# check availabylity to recover amount
trap 'echo LC TIMEOUT EXIT' EXIT
recover_amount=`$CALL_LC -rc "runmethod $elector_addr compute_returned_stake 0x$val_acc_addr" -rc "quit" 2>/dev/null | grep "result:" | awk '{print $3}' | tee ${ELECTIONS_WORK_DIR}/recover-amount`
trap - EXIT
echo "INFO: recover_amount = ${recover_amount} nanotokens ( $((recover_amount/1000000000)) Tokens )"

########################################################################################
# return stake by lite-client

if [ "$recover_amount" != "0" ]; then
    #=================================================
    # prepare recovery boc
    echo "INFO: Prepare recovery request ..."
    $CALL_FIFT -s recover-stake.fif "${ELECTIONS_WORK_DIR}/recover-query.boc"

    recover_query_payload=$(base64 "${ELECTIONS_WORK_DIR}/recover-query.boc" |tr -d "\n")

    TVM_OUTPUT=$($HOME/bin/tvm_linker message $val_acc_addr \
	-a ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
	-m submitTransaction \
	-p "{\"dest\":\"$elector_addr\",\"value\":1000000000,\"bounce\":true,\"allBalance\":false,\"payload\":\"$recover_query_payload\"}" \
	-w -1 \
	--setkey ${KEYS_DIR}/msig.keys.bin | tee ${ELECTIONS_WORK_DIR}/TVM_linker-recquery.log)

    if [[ -z $(echo $TVM_OUTPUT | grep "boc file created") ]];then
        echo "###-ERROR: TVM linker CANNOT create boc file!!! Can't continue."
        exit 1
    fi

    mv "$(echo "$val_acc_addr"| cut -c 1-8)-msg-body.boc" "${ELECTIONS_WORK_DIR}/recover-msg.boc"
    echo "INFO: Prepare recovery request ... DONE"
    #=================================================
    # do request for return
    echo "INFO: Process recovery request by lite-client ..."
    trap 'echo LC TIMEOUT EXIT' EXIT
    `$CALL_LC -rc "sendfile ${ELECTIONS_WORK_DIR}/recover-msg.boc" -rc "quit" &> ${ELECTIONS_WORK_DIR}/recovry-request.log`
    trap - EXIT

    LC_OUTPUT=`cat ${ELECTIONS_WORK_DIR}/recovry-request.log | grep "external message status is 1"`
    if [[ -z $LC_OUTPUT ]]; then
	    echo "###-ERROR: Send message for recovering FAILED!!!"
	    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
	    exit 1
    fi

	echo "INFO: Recovery request was sent SUCCESSFULLY for $((recover_amount/1000000000))"
	echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
	"${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "Requested $((recover_amount/1000000000))" 2>&1 > /dev/null
	exit 0
    
else
    echo "INFO: nothing to recover"
fi

########################################################################################
# Check election conditions

if [ "$election_id" == "0" ]; then
    date +"INFO: %F %T No current elections"
    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
    exit 0
fi

if [ -f "${ELECTIONS_WORK_DIR}/stop-election" ]; then
    date +"INFO: %F %T Election stopped"
    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
    exit 0
fi

#####################################################################################
# Check already in participant list
# public key : [ stake, max_factor, wallet (addr), adnl (adnl_addr) ]
echo "INFO: Check you participate already ... "
Curr_ADNL_Key=`cat ${ELECTIONS_WORK_DIR}/$election_id | grep "ADNL key:" | awk '{print $3}'`
Dec_Curr_ADNL_Key=$(hex2dec "$Curr_ADNL_Key")
dec_val_acc_addr=$(hex2dec "$val_acc_addr")

# check in participant list by account address
trap 'echo LC TIMEOUT EXIT' EXIT
LC_OUTPUT="$($CALL_LC -rc "runmethodfull $elector_addr participant_list_extended" -rc "quit" 2>/dev/null | grep 'result:' | tr "]]" "\n" | tr '[' '\n' | awk 'NF > 0'| tee ${ELECTIONS_WORK_DIR}/Curr-Validator.lst)"
trap - EXIT

ADDR_FOUND=`echo "${LC_OUTPUT}"  | grep "$dec_val_acc_addr" | awk '{print $3}'`

if [[ ! -z $ADDR_FOUND ]];then
    echo
    echo "INFO: You participate already in this elections ($election_id)"
    Your_Stake=`echo "${LC_OUTPUT}" | grep "$dec_val_acc_addr" | awk '{print $1 / 1000000000}'`
    Your_ADNL=`echo "${LC_OUTPUT}"  | grep "$dec_val_acc_addr" | awk '{print $4}'`
    echo "---INFO: Your stake: $Your_Stake with ADNL: $(echo "$Curr_ADNL_Key" | tr "[:upper:]" "[:lower:]")"
    echo
    exit 0
fi

# check in participant list by ADNL key
if [[ ! -z $Curr_ADNL_Key ]];then
    trap 'echo LC TIMEOUT EXIT' EXIT
    LC_OUTPUT="$($CALL_LC -rc "runmethodfull $elector_addr participant_list_extended" -rc "quit" 2>/dev/null | grep 'result:' | tr "]]" "\n" | tr '[' '\n' | awk 'NF > 0')"
    trap - EXIT
    Found_ADNL=`echo "${LC_OUTPUT}" | grep "$Dec_Curr_ADNL_Key" | awk '{print $4}'`
    if [[ -z $Found_ADNL ]];then
        echo "INFO: Current ADNL: $Curr_ADNL_Key / $Dec_Curr_ADNL_Key"
        echo "INFO: You ADNL not found in curreent participant list. Let's go to elections..."
    else
        Your_Stake=`echo "${LC_OUTPUT}" | grep "$Dec_Curr_ADNL_Key" | awk '{print $1 / 1000000000}'`
    echo
    echo "INFO: You are already participating in this elections ($election_id)"
        echo "---INFO: Your stake: $Your_Stake and ADNL: $(echo "$Curr_ADNL_Key" | tr "[:upper:]" "[:lower:]")"
        exit 0
    fi
else
    echo "INFO: This is your first try for elections ID: $election_id ..."
fi

####################################################################################
# check balance
echo "INFO: Check account balance ..."
ACCOUNT_INFO=`$CALL_LC -rc "getaccount ${MSIG_ADDR}" -t "3" -rc "quit" 2>/dev/null `
AMOUNT=`echo "$ACCOUNT_INFO" |grep "account balance" | tr -d "ng"|awk '{print $4}'`
VALIDATOR_ACTUAL_BALANCE=$((AMOUNT / 1000000000))                                         # in tokens
echo "INFO: ${MSIG_ADDR} VALIDATOR_ACTUAL_BALANCE = ${VALIDATOR_ACTUAL_BALANCE} tokens"
echo "INFO: STAKE = $STAKE tokens"

if [ "$STAKE" -ge ${VALIDATOR_ACTUAL_BALANCE} ]; then
    echo "###-ERROR: not enough tokens in ${MSIG_ADDR} wallet"
    echo "INFO: VALIDATOR_ACTUAL_BALANCE = ${VALIDATOR_ACTUAL_BALANCE}"
    echo "INFO: $(basename "$0") END $(date +%s) / $(date)"
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "###-ERROR: not enough tokens in ${MSIG_ADDR} wallet. Balance: $VALIDATOR_ACTUAL_BALANCE" 2>&1 > /dev/null
    exit 1
fi

# check min validator stake
MIN_STAKE=`$CALL_LC -rc 'getconfig 17' -rc quit 2>&1 | grep -C 1 min_stake | grep value | awk -F: '{print $4}' | tr -d ')'` # in nanotokens
MIN_STAKE=$((MIN_STAKE / 1000000000)) # in tokens
echo "INFO: MIN_STAKE = ${MIN_STAKE} tokens"

if [ "$STAKE" -lt "${MIN_STAKE}" ]; then
    echo "ERROR: STAKE ($STAKE tokens) is less than MIN_STAKE (${MIN_STAKE} tokens)"
    exit 1
fi

########################################################################################
# Prepare for elections
date +"INFO: %F %T Current elections ID: $election_id"
cp "${ELECTIONS_WORK_DIR}/election-id" "${ELECTIONS_WORK_DIR}/active-election-id"

#=================================================
# Get Elections parametrs (p15)
echo "INFO: Get elections parametrs (p15)"
trap 'echo LC TIMEOUT EXIT' EXIT
CONFIG_PAR_15=`$CALL_LC -rc "getconfig 15" -rc "quit" 2>/dev/null |tee "${ELECTIONS_WORK_DIR}/elector-params" | grep -i "ConfigParam(15)"`
trap - EXIT
validators_elected_for=`echo $CONFIG_PAR_15 | awk '{print $4}'| awk -F ":" '{print $2}'`
elections_start_before=`echo $CONFIG_PAR_15 | awk '{print $5}'| awk -F ":" '{print $2}'`
elections_end_before=`echo $CONFIG_PAR_15   | awk '{print $6}'| awk -F ":" '{print $2}'`
stake_held_for=`echo $CONFIG_PAR_15         | awk '{print $7}'| awk -F ":" '{print $2}' | tr -d ')'`
if [[ -z $validators_elected_for ]] || [[ -z $elections_start_before ]] || [[ -z $elections_end_before ]] || [[ -z $stake_held_for ]];then
    echo "###-ERROR: Get network election params (p15) FAILED!!!"
    exit 1
fi
#=================================================
# Generate new elections key
echo "INFO: Generate new elections key ..."
NewElectionKey=`cat ${ELECTIONS_WORK_DIR}/$election_id | grep "Elections key:" | awk '{print $3}'` 
if [[ -z $NewElectionKey ]];then
    trap 'echo VC TIMEOUT EXIT' EXIT
    NewElectionKey=`$CALL_VC -c "newkey" -c "quit" 2>/dev/null | tee "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-election-key" | grep "created new key" | awk '{print $4}'`
    trap - EXIT
    if [[ -z $NewElectionKey ]];then
        echo "###-E RROR: Generate new election key FAILED!!!"
        exit 1
    fi
    echo "Elections key: $NewElectionKey" >> ${ELECTIONS_WORK_DIR}/$election_id
else
    echo "INFO: New election key generated alredy."
fi
echo "INFO: New election key: $NewElectionKey"
NewElectionKey=`cat ${ELECTIONS_WORK_DIR}/$election_id | grep "Elections key:" | awk '{print $3}'`
#=================================================
# Generate election ADNL key
echo "INFO: Generate new ADNL key ..."
New_ADNL_Key=`cat ${ELECTIONS_WORK_DIR}/$election_id | grep "ADNL key:" | awk '{print $3}'` 
if [[ -z $New_ADNL_Key ]];then
    trap 'echo VC TIMEOUT EXIT' EXIT
    New_ADNL_Key=`$CALL_VC -c "newkey" -c "quit" 2>/dev/null | tee "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-election-adnl-key" | grep "created new key" | awk '{print $4}'`
    trap - EXIT
    if [[ -z $New_ADNL_Key ]];then
        echo "###-ERROR: Generate new ADNL key FAILED!!!"
        exit 1
    fi
    echo "ADNL key: $New_ADNL_Key" >> ${ELECTIONS_WORK_DIR}/$election_id
else
    echo "INFO: New ADNL key generated alredy."
fi
echo "INFO: New ADNL key: $New_ADNL_Key"

#=================================================
# Check keys in the engine

VC_OUTPUT=`$CALL_VC -c "getvalidators" -c "quit" | tee "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-current-engine-keys"`



#=================================================
# run1.1
# Add new keys to engine
echo "INFO: Add new keys to engine ..."
Validating_Start=${election_id}
Validating_Stop=$(( ${Validating_Start} + 1000 + ${validators_elected_for} + ${elections_start_before} + ${elections_end_before} + ${stake_held_for} ))
echo "Validating_Start: $Validating_Start | Validating_Stop: $Validating_Stop"

trap 'echo VC TIMEOUT EXIT' EXIT
VC_OUTPUT=`$CALL_VC \
    -c "addpermkey $NewElectionKey $Validating_Start $Validating_Stop" \
    -c "addtempkey $NewElectionKey $NewElectionKey $Validating_Stop" \
    -c "addadnl $New_ADNL_Key 0" \
    -c "addvalidatoraddr $NewElectionKey $New_ADNL_Key $Validating_Stop" \
    -c "quit"` | tee ${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-engine-add-keys-log
trap - EXIT

if [[ ! -z $(echo "$VC_OUTPUT" | grep "duplicate election date") ]];then
    echo "###-WARNING: New keys was added to engine already !!!"
fi
echo "INFO: Add new keys to engine ... DONE"
#=================================================
# run1.2
# make request SC signature
SC_Signature=$($CALL_FIFT -s validator-elect-req.fif $MSIG_ADDR $Validating_Start $MAX_FACTOR $New_ADNL_Key \
        ${ELECTIONS_WORK_DIR}/validator-to-sign.bin \
        | tee "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-lt-request-dump" \
        | sed -n 2p)

if [[ -z $SC_Signature ]];then
    echo "###-ERROR: validator-elect-req.fif NOT processed !!! Can't continue."
    exit 1
else
    echo "INFO: validator-elect-req.fif: $SC_Signature "
fi

#=================================================
# run2
# Signing New Public_Key
echo "INFO: Signing New Public_Key ..."
trap 'echo VC TIMEOUT EXIT' EXIT
VC_OUTPUT=$($CALL_VC \
    -c "exportpub $NewElectionKey" \
    -c "sign $NewElectionKey $SC_Signature" \
    -c "quit" \
    | tee  "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-lt-request-dump1")
trap - EXIT
Public_Key=`echo "${VC_OUTPUT}" | grep "got public key" | awk '{print $4}'`
Signature=`echo "${VC_OUTPUT}" | grep "got signature" | awk '{print $3}'`

if [[ -z $Public_Key ]] || [[ -z $Signature ]];then
    echo "###-ERROR: Signing  NewElectionKey FAILED!!! Can't continue."
    exit 1
else
    echo "INFO: Public_Key: $Public_Key"
    echo "INFO: Signature:  $Signature"
    echo "INFO: Signing New Public_Key ... DONE "
fi

#=================================================
# run3
# Create validator-query.boc
echo "INFO: Create validator-query.boc ..."
FIFT_OUTPUT=$($CALL_FIFT -s validator-elect-signed.fif $MSIG_ADDR $Validating_Start $MAX_FACTOR $New_ADNL_Key $Public_Key $Signature \
    ${ELECTIONS_WORK_DIR}/validator-query.boc \
    | tee "${ELECTIONS_WORK_DIR}/${VALIDATOR_NAME}-lt-request-dump2" )


if [[ -z $(echo "$FIFT_OUTPUT" | grep "Message body is" | awk '{print $4}') ]];then
    echo "###-ERROR: ${ELECTIONS_WORK_DIR}/validator-query.boc NOT created!!! Can't continue"
    exit 1
else
    echo "INFO: ${ELECTIONS_WORK_DIR}/validator-query.boc Created"
fi

######################################################################################################
# prepare validator query to elector contract using multisig for lite-client

NANOSTAKE=$((STAKE*1000000000))
echo "INFO: NANOSTAKE = $NANOSTAKE nanotokens"

validator_query_payload=$(base64 "${ELECTIONS_WORK_DIR}/validator-query.boc" |tr -d "\n")
# ===============================================================
# parameters checks
if [[ -z $validator_query_payload ]];then
    echo "###-ERROR: Payload is empty! It is unasseptable!"
    echo "did you have right validator-query.boc ?"
    exit 2
fi

if [[ -z $val_acc_addr ]];then
    echo "###-ERROR: Validator Address empty! It is unasseptable!"
    echo "Check keys files."
    exit 2
fi

if [[ -z $elector_addr ]];then
    echo "###-ERROR: Elector Address empty! It is unasseptable!"
    exit 2
fi

if [[ ! -f ${KEYS_DIR}/msig.keys.bin ]];then
    echo "###-ERROR: ${KEYS_DIR}/msig.keys.bin NOT FOUND! Can't continue"
    exit 2
fi

if [[ ! -f ${CONFIGS_DIR}/SafeMultisigWallet.abi.json ]];then
    echo "###-ERROR: ${CONFIGS_DIR}/SafeMultisigWallet.abi.json NOT FOUND! Can't continue"
    exit 2
fi


# ===============================================================
# make boc for lite-client
echo "INFO: Make boc for lite-client ..."
TVM_OUTPUT=$($HOME/bin/tvm_linker message $val_acc_addr \
    -a ${CONFIGS_DIR}/SafeMultisigWallet.abi.json \
    -m submitTransaction \
    -p "{\"dest\":\"$elector_addr\",\"value\":$NANOSTAKE,\"bounce\":true,\"allBalance\":false,\"payload\":\"$validator_query_payload\"}" \
    -w -1 --setkey ${KEYS_DIR}/msig.keys.bin | tee ${ELECTIONS_WORK_DIR}/TVM_linker-valquery.log)

if [[ -z $(echo $TVM_OUTPUT | grep "boc file created") ]];then
    echo "###-ERROR: TVM linker CANNOT create boc file!!! Can't continue."
    exit 1
fi

mv "$(echo "$val_acc_addr"| cut -c 1-8)-msg-body.boc" "${ELECTIONS_WORK_DIR}/vaidator-msg.boc"
echo "INFO: Make boc for lite-client ... DONE"
#####################################################################################################
###############  Send query by lite-client ##########################################################
#####################################################################################################

echo "INFO: Send query to Elector by lite-client ..."

trap 'echo LC TIMEOUT EXIT' EXIT
$CALL_LC -rc "sendfile ${ELECTIONS_WORK_DIR}/vaidator-msg.boc" -rc 'quit' &> ${ELECTIONS_WORK_DIR}/validator-req-result.log
trap - EXIT

vr_result=`cat ${ELECTIONS_WORK_DIR}/validator-req-result.log | grep "external message status is 1"`

if [[ -z $vr_result ]]; then
    echo "###-ERROR: Send message for eletction FAILED!!!"
    "${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "###-ERROR: Send message for eletction FAILED!!!" 2>&1 > /dev/null
    exit 1
fi

echo "INFO: Submit transaction for elections was done SUCCESSFULLY!"

FUTURE_CYCLE_ADNL=`echo $New_ADNL_Key | tr "[:upper:]" "[:lower:]"`
echo "INFO: Sent $STAKE for elections. ADNL: $FUTURE_CYCLE_ADNL"

"${SCRIPT_DIR}/Send_msg_toTelBot.sh" "$HOSTNAME Server" "Sent $STAKE for elections. ADNL: $FUTURE_CYCLE_ADNL" 2>&1 > /dev/null

date +"INFO: %F %T prepared for elections"
echo "INFO: $(basename "$0") FINISHED $(date +%s) / $(date)"

trap - EXIT
exit 0



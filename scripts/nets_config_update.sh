#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

echo "Current network is $NETWORK_TYPE"

GLB_CFG_FNAME="ton-global.config.json"
TLC_CFG_FNAME="ton-lite-client.config.json"

MAIN_GLB_URL="https://raw.githubusercontent.com/tonlabs/main.ton.dev/master/configs/ton-global.config.json"
NET_GLB_URL="https://raw.githubusercontent.com/tonlabs/net.ton.dev/master/configs/net.ton.dev/ton-global.config.json"
FLG_GLB_URL="https://raw.githubusercontent.com/FreeTON-Network/fld.ton.dev/main/configs/fld.ton.dev/ton-global.config.json"

MAIN_TLC_URL="https://raw.githubusercontent.com/tonlabs/main.ton.dev/master/configs/ton-lite-client.config.json"
NET_TLC_URL="xxx"
FLG_TLC_URL="https://raw.githubusercontent.com/FreeTON-Network/fld.ton.dev/main/configs/fld.ton.dev/ton-lite-client.config.json"

MAIN_CFG_DIR="$CONFIGS_DIR/main.ton.dev"
NET_CFG_DIR="$CONFIGS_DIR/net.ton.dev"
FLD_CFG_DIR="$CONFIGS_DIR/fld.ton.dev"

[[ ! -d $HOME/logs ]] && mkdir -p 

declare -a g_url_list=($MAIN_GLB_URL $NET_GLB_URL $FLG_GLB_URL)
declare -a t_url_list=($MAIN_TLC_URL $NET_TLC_URL $FLG_TLC_URL)
declare -a dir_list=($MAIN_CFG_DIR $NET_CFG_DIR $FLD_CFG_DIR)

for i in $(seq 0 2)
do
    [[ ! -d ${dir_list[i]} ]] && mkdir -p ${dir_list[i]}
    curl -o ${dir_list[i]}/$GLB_CFG_FNAME ${g_url_list[i]}
    if [[ ! "${t_url_list[i]}" == "xxx" ]];then
        curl -o ${dir_list[i]}/$TLC_CFG_FNAME ${t_url_list[i]}
    fi
done

cp -f "${CONFIGS_DIR}/${NETWORK_TYPE}/$GLB_CFG_FNAME" "${TON_WORK_DIR}/etc/$GLB_CFG_FNAME"

exit 0

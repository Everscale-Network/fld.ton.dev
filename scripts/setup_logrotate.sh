#!/bin/bash

# (C) Sergey Tyurin  2020-01-12 19:00:00

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
. "${SCRIPT_DIR}/env.sh"

OS_SYSTEM=`uname`
if [[ "$OS_SYSTEM" == "Linux" ]];then
    SETUP_USER="$(id -u)"
    SETUP_GROUP="$(id -g)"
else
    SETUP_USER="$(id -un)"
    SETUP_GROUP="$(id -gn)"
fi

#============================================
# set log rotate
# NB! - should be log '>>'  in run.sh or 'append' in service
LOGROT_FILE="/etc/logrotate.d/tonnode"
NODE_LOG_ROT=$(cat <<-_ENDNLR_
$TON_LOG_DIR/node.log {
    daily
    copytruncate
    dateext
    dateyesterday
    missingok
    rotate 7
    maxage 30
    compress
    delaycompress
    notifempty
    sharedscripts
}
_ENDNLR_
)
if [[ "$OS_SYSTEM" == "Linux" ]];then
    sudo echo "$NODE_LOG_ROT" > tmp.txt
    sudo mv -f tmp.txt ${LOGROT_FILE}
    sudo chown root:root ${LOGROT_FILE}
    sudo chmod 644 ${LOGROT_FILE}
    [[ "$(hostnamectl |grep 'Operating System'|awk '{print $3}')" == "CentOS" ]] && sudo chcon system_u:object_r:etc_t:s0 ${LOGROT_FILE}

else
    echo "###-ERROR: Logrotate for FreeBSD not implemented yet. Will using rotate log through crontab."
fi

ls -alhFpZ ${LOGROT_FILE}

exit 0

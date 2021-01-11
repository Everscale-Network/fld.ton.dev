#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

verb="${1:-1}"

echo "Update networks global configs ..."
$SCRIPT_DIR/nets_config_update.sh
echo

VAL_PID=`ps -ax | grep "validator\-engine" | awk '{print $1}'`
echo "Engine PID: $VAL_PID"

# Kill engine process
echo "Killing engine..."
kill $VAL_PID
while true
do
    VAL_PID=`ps -ax | grep "validator\-engine"| grep -v "validator\-engine\-console" | awk '{print $1}'`
    #echo "### - Node steel works! Engine PID: $VAL_PID"
    if [[ -z $VAL_PID ]]; then
        echo "### Dead!"
    break
    fi
    printf "."
done

rm -f /var/nodelog/vm-log

./run.sh $verb

VAL_PID=`ps -ax | grep "validator\-engine" | awk '{print $1}'`
if [[ -z $VAL_PID ]]; then
  while true
  do
    ./run.sh $verb
    VAL_PID=`ps -ax | grep "validator\-engine" | awk '{print $1}'`
    [[ ! -z $VAL_PID ]] && break
    echo "### - ALARM !!! Can't start engine."
  done
fi

exit 0


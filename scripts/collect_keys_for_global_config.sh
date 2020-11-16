#!/bin/bash

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

awk '{
    if ($3 == "\"engine.dht\",") {
        line = NR + 1
    } else if ((line > 0) && (line == NR)) {
        system("echo " $3 " | base64 -d | od -t x1 -An | tr -d \" \\n\"")
    }
}' "${TON_WORK_DIR}/db/config.json" > "./${HOSTNAME}-dht"

awk -v validator="$HOSTNAME" -v ADNL_PORT="${ADNL_PORT}" -v UTILS_DIR="${UTILS_DIR}" -v TON_WORK_DIR="${TON_WORK_DIR}" \
    '{
    if (NR == 1) {
        key = toupper($1)
    } else if ($1 == "\"ip\"") {
        ip = $3
            printf UTILS_DIR "/generate-random-id -m dht -a ";
        printf "\"{";
        printf "    \\\"@type\\\" : \\\"adnl.addressList\\\",";
        printf "    \\\"addrs\\\" : [";
        printf "        {";
        printf "            \\\"@type\\\" : \\\"adnl.address.udp\\\",";
        printf "            \\\"ip\\\" : " ip;
        printf "            \\\"port\\\" : " ADNL_PORT;
        printf "        }";
        printf "    ]";
        printf "}\" ";
        printf "-k " TON_WORK_DIR "/db/keyring/" key;
        print  " > " "./" validator "-glb-dht"
    }
}' "./${HOSTNAME}-dht" "${TON_WORK_DIR}/db/config.json" > "./tmp_cmd.sh"

chmod +x tmp_cmd.sh
./tmp_cmd.sh

rm -f tmp_cmd.sh

exit 0

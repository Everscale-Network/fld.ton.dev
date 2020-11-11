#!/bin/bash -eE

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

echo "INFO: build utils (tonos-cli)..."

rm -rf "${TONOS_CLI_SRC_DIR}"
git clone https://github.com/tonlabs/tonos-cli.git "${TONOS_CLI_SRC_DIR}"
cd "${TONOS_CLI_SRC_DIR}"

cargo update
cargo build --release

cp -f "${TONOS_CLI_SRC_DIR}/target/release/tonos-cli" "${UTILS_DIR}/"
cp -f $TON_BUILD_DIR/utils/tonos-cli $HOME/bin

echo "INFO: build utils (tonos-cli)... DONE"
echo
$HOME/bin/tonos-cli version
echo

exit 0

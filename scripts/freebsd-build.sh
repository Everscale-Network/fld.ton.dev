#!/bin/bash -eE

function pause(){
 read -s -n 1 -p "Press any key to continue . . ."
 echo ""
}

[[ ! -d $HOME/bin ]] && mkdir -p $HOME/bin

SCRIPT_DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

if [ "${INSTALL_DEPENDENCIES}" = "yes" ]; then
    if ! sudo -V >/dev/null ; then
        echo "Looks like sudo is not installed. You need to install it to proceed with dependencies installation"
        exit 0
    fi
    echo "INFO: install dependencies..."
    sudo pkg update -f && sudo pkg install -y \
	git \
	wget \
	gawk \
	base64 \
	gflags \
	libmicrohttpd \
	ccache \
        cmake \
        curl \
        gperf \
        openssl \
        ninja \
        lzlib \
	jq \
	vim \
	gsl

    curl https://sh.rustup.rs -sSf | sh -s -- -y
    #shellcheck source=$HOME/.cargo/env
    . "$HOME/.cargo/env"
    rustup update
    echo "INFO: install dependencies... DONE"
fi

rm -rf "${TON_SRC_DIR}"

echo "INFO: clone ${TON_GITHUB_REPO} (${TON_STABLE_GITHUB_COMMIT_ID})..."
git clone --recursive "${TON_GITHUB_REPO}" "${TON_SRC_DIR}"
cd "${TON_SRC_DIR}" && git checkout "${TON_STABLE_GITHUB_COMMIT_ID}"
echo "INFO: clone ${TON_GITHUB_REPO} (${TON_STABLE_GITHUB_COMMIT_ID})... DONE"

echo "INFO: build a node..."
mkdir -p "${TON_BUILD_DIR}"
cd "${TON_BUILD_DIR}"

cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPORTABLE=OFF

# ====================================================================
# sed -i.bak 's%TD_LINUX%TD_LINUX \|\| TD_FREEBSD%g' "${TON_SRC_DIR}/memprof/memprof/memprof.cpp"
# sed -i.bak 's%TD_LINUX%TD_LINUX \|\| TD_FREEBSD%g' "${TON_SRC_DIR}/tdutils/td/utils/port/FileFd.cpp"
# sed -i.bak 's%TD_LINUX%TD_LINUX \|\| TD_FREEBSD%g' "${TON_SRC_DIR}/tdutils/td/utils/port/rlimit.cpp"
# sed -i.bak 's%TD_LINUX%TD_LINUX \|\| TD_FREEBSD%g' "${TON_SRC_DIR}/tdutils/td/utils/port/user.cpp"
# ====================================================================

ninja

echo "INFO: build a node... DONE"

echo "INFO: build utils (convert_address)..."
cd "${NET_TON_DEV_SRC_TOP_DIR}/utils/convert_address"
cargo update
cargo build --release
cp "${NET_TON_DEV_SRC_TOP_DIR}/utils/convert_address/target/release/convert_address" "${UTILS_DIR}/"
echo "INFO: build utils (convert_address)... DONE"

echo "INFO: build utils (tonos-cli)..."
rm -rf "${TONOS_CLI_SRC_DIR}"
git clone https://github.com/tonlabs/tonos-cli.git "${TONOS_CLI_SRC_DIR}"
cd "${TONOS_CLI_SRC_DIR}"
cargo update
cargo build --release
cp -f "${TONOS_CLI_SRC_DIR}/target/release/tonos-cli" "${UTILS_DIR}/"
echo "INFO: build utils (tonos-cli)... DONE"

rm -rf "${NET_TON_DEV_SRC_TOP_DIR}/ton-labs-contracts"
git clone https://github.com/tonlabs/ton-labs-contracts.git "${NET_TON_DEV_SRC_TOP_DIR}/ton-labs-contracts"
rm -f "${CONFIGS_DIR}/SafeMultisigWallet.tvc"
rm -f "${CONFIGS_DIR}/SafeMultisigWallet.abi.json"
cp -f "${NET_TON_DEV_SRC_TOP_DIR}/ton-labs-contracts/solidity/safemultisig/SafeMultisigWallet.tvc" "${CONFIGS_DIR}"
cp -f "${NET_TON_DEV_SRC_TOP_DIR}/ton-labs-contracts/solidity/safemultisig/SafeMultisigWallet.abi.json" "${CONFIGS_DIR}"

cp -f $TON_BUILD_DIR/lite-client/lite-client $HOME/bin
cp -f $TON_BUILD_DIR/utils/tonos-cli $HOME/bin
cp -f $TON_BUILD_DIR/validator-engine/validator-engine $HOME/bin
cp -f $TON_BUILD_DIR/validator-engine-console/validator-engine-console $HOME/bin

#=========================================================
# build TVM-linker
echo "INFO: build TVM-linker ..."
cd $HOME
rm -rf $HOME/TVM-linker
git clone https://github.com/tonlabs/TVM-linker.git
cd $HOME/TVM-linker/tvm_linker/
cargo build --release
cp -f $HOME/TVM-linker/tvm_linker/target/release/tvm_linker $HOME/bin/
echo "INFO: build TVM-linker DONE."











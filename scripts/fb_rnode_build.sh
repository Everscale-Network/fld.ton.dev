#!/bin/bash
# (C) Sergey Tyurin  2021-01-02 10:00:00

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

sudo pkg install -y \
    mc libtool \
    perl5 \
    automake \
    llvm-devel \
    gmake \
    git \
    jq \
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
    lzlib

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup update

[[ -d ${RNODE_SRC_DIR} ]] && rm -rf ${RNODE_SRC_DIR}

git clone --recurse-submodules https://github.com/tonlabs/ton-labs-node.git $RNODE_SRC_DIR
cd $RNODE_SRC_DIR
cargo update

sed -i.bak 's%features = \[\"cmake_build\", \"dynamic_linking\"\]%features = \[\"cmake_build\"\]%g' Cargo.toml

#cargo build --release
cargo build --release --features "external_db,metrics"

[[ ! -d $HOME/bin ]] && mkdir -p $HOME/bin
cp -f ${RNODE_SRC_DIR}/target/release/ton_node $HOME/bin/rnode

exit 0

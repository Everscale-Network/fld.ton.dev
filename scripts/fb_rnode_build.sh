#!/bin/bash

[[ -d $HOME/rnode ]] && rm -rf $HOME/rnode

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
#shellcheck source=$HOME/.cargo/env
source "$HOME/.cargo/env"
rustup update

git clone https://github.com/tonlabs/ton-labs-node.git rnode
cd rnode
git submodule init
git submodule update
cargo update
cargo build --release

[[ ! -d $HOME/bin ]] && mkdir -p $HOME/bin
cp -f $HOME/rnode/target/release/ton_node $HOME/bin/rnode


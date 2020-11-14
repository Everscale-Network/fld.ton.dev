# README

## **ANY TOKENS IN THIS NETWORK ARE INTENDED FOR TESTING PURPOSES ONLY AND ARE NO OTHER PURPOSE. THE NETWORK RESTART FREQUENTLY AND ALL TOKENS WILL BE LOST** 

**This repository of Free TON node has purpose to develop and test any kind of cases which can be dangerous for developer network and moreover main network. You are welcome for any activity which you can imagine! NO limits at all!**
# Getting Started

## 1. Minimal System Requirements
| Configuration | CPU (cores) | RAM (GiB) | Storage (GiB) | Network (Gbit/s)|
|---|:---|:---|:---|:---|
| Recommended |12|64|500|1| 

**SSD NVMe** disks are required for /var/ton-work storage.

Highly advise you to have separate disks:

- SSD disk for system, programs & etc

- dedicated NVMe SSD disk for /var/ton-work

**Recommended kernel version for Linux >5.4**

## 2. Prerequisites
### 2.1 Clone repository
clone this repositiry to your home folder
```csharp
cd 
git clone https://github.com/FreeTON-Network/fld.ton.dev.git
```
Adjust (if needed) `~/fld.ton.dev/scripts/env.sh`
    
### 2.2 Build Node
Build a node:  
#### 2.2.1 Build on Ubuntu 20.04
    $ cd ~/fld.ton.dev/scripts/
    $ ./ubuntu-build.sh
#### 2.2.2 Build on CentOS 8.2
    $ cd ~/fld.ton.dev/scripts/
    $ ./cent_build.sh
#### 2.2.3 Build on FreeBSD 12.1
    $ cd ~/fld.ton.dev/scripts/
    $ ./freebsd-build.sh 

### 2.3 Setup Node
#### 2.3.1 Setup on Ubuntu 20.04
Initialize a node:

    $ ./setup.sh
#### 2.3.2 Setup on CentOS 8.2
Initialize a node:

    $ ./setup.sh
#### 2.3.3 Setup on FreeBSD 12.1
Initialize a node:

    $ ./fb-setup.sh
### 2.4 Run node

    $ ./run.sh
Check node sync (can take few hours for first time):

    ./check_node_sync_status.sh
### 2.5 Receive 100k tokens to your validator account

    cd ~/fld.ton.dev/scripts/
    Marvin=0:deda155da7c518f57cb664be70b9042ed54a92542769735dfb73d3eef85acdaf
    DST_ACCOUNT=<your addr>  
    tonos-cli call "$Marvin" grant "{\"addr\":\"$DST_ACCOUNT\"}" --abi Marvin.abi.json

### 2.6 Informations & support
All other information you can find on Free TON Wiki:  
https://en.freeton.wiki/Free_TON_Wiki

Main Free TON site:  https://freeton.org

Telegram chat to support this particular test network: https://t.me/fld_ton_dev  (main language is Russian)

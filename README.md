# README

**This repository of Free TON node has purpose to develop and test any kind of cases which can be dangerous for developer network and moreover main network. You are welcom for any activity which you can imagine! NO limits at all!**
# Getting Started

## 1. Minimal System Requirements
| Configuration | CPU (cores) | RAM (GiB) | Storage (GiB) | Network (Gbit/s)|
|---|:---|:---|:---|:---|
| Recommended |12|64|500|1| 

**SSD NVMe** disks are required for /var/ton-work/db storage. 

**Recommended kernel for Linux > 5.4**
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
### 2.4 Wiki
All other information you can find on Free TON Wiki:  
https://en.freeton.wiki/Free_TON_Wiki

#!/bin/bash

mode="$1"
ubuntu_version=$(lsb_release -r -s)

if [ $ubuntu_version == "18.04" ]; then
  wget https://content.mellanox.com/ofed/MLNX_OFED-4.9-5.1.0.0/MLNX_OFED_LINUX-4.9-5.1.0.0-ubuntu18.04-x86_64.tgz
  mv MLNX_OFED_LINUX-4.9-5.1.0.0-ubuntu18.04-x86_64.tgz ofed.tgz
elif [ $ubuntu_version == "20.04" ]; then
  wget https://content.mellanox.com/ofed/MLNX_OFED-4.9-5.1.0.0/MLNX_OFED_LINUX-4.9-5.1.0.0-ubuntu20.04-x86_64.tgz
  mv MLNX_OFED_LINUX-4.9-5.1.0.0-ubuntu20.04-x86_64.tgz ofed.tgz
else
  echo "Wrong ubuntu distribution for $mode!"
  exit 0
fi
echo $mode $ubuntu_version $ofed_fid

# install anaconda
mkdir install
mv ofed.tgz install

# install ofed
cd install
if [ ! -d "./ofed" ]; then
  tar zxf ofed.tgz
  mv MLNX* ofed
fi

# Download MiniForge
if [ ! -f "./Mambaforge-24.7.1-0-Linux-x86_64.sh" ]; then
  wget https://github.com/conda-forge/miniforge/releases/download/24.7.1-0/Mambaforge-24.7.1-0-Linux-x86_64.sh
fi

# Download cmake
if [ ! -f cmake-3.16.8.tar.gz ]; then
  wget https://cmake.org/files/v3.16/cmake-3.16.8.tar.gz
fi

# Download Miniforge
if [ ! -d "$HOME/mambaforge" ]; then
  bash Mambaforge-24.7.1-0-Linux-x86_64.sh
fi


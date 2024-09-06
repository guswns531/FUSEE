#!/bin/bash

sudo apt update -y
sudo apt install memcached -y
sudo apt install libtbb-dev libboost-all-dev -y
sudo apt-get install libssl-dev -y 
sudo apt install -y numactl

cd install/ofed
sudo ./mlnxofedinstall --force
sudo /etc/init.d/openibd restart

cd ..
if [ ! -d "./cmake-3.16.8" ]; then
  tar zxf cmake-3.16.8.tar.gz
  cd cmake-3.16.8 && ./configure && make -j 4 && sudo make install
else
  cd cmake-3.16.8 && sudo make install
fi

# install gtest
if [ ! -d "/usr/src/gtest" ]; then
  sudo apt install -y libgtest-dev
fi
cd /usr/src/gtest
sudo /usr/local/bin/cmake .
sudo make

cd ~
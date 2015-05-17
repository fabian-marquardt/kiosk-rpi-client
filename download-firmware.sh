#!/bin/bash
set -e
PWD=$(pwd)
FWDIR=$PWD/firmware

wget https://github.com/raspberrypi/firmware/archive/master.tar.gz
tar xzvf master.tar.gz
mv firmware-master $FWDIR
rm master.tar.gz

#!/bin/bash
source config.sh

check_config
set -e

wget https://github.com/raspberrypi/firmware/archive/master.tar.gz
tar xzvf master.tar.gz
mv firmware-master $FWDIR
rm master.tar.gz

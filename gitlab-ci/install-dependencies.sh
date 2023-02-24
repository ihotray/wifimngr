#!/bin/bash

set -euxo pipefail

echo "install dependencies"

pwd

# libwifi
cd /opt/dev
rm -fr easy-soc-libs
git clone https://dev.iopsys.eu/iopsys/easy-soc-libs.git
cd easy-soc-libs
git checkout 784d14ce59f7d11d8fa24c777ffa41d0c5a65c47
cd libeasy
make CFLAGS+="-I/usr/include/libnl3"
mkdir -p /usr/include/easy
cp easy.h event.h utils.h if_utils.h debug.h hlist.h /usr/include/easy
cp -a libeasy*.so* /usr/lib
cd ../libwifi
make WIFI_TYPE=TEST
cp wifidefs.h wifiutils.h wifiops.h wifi.h /usr/include
cp -a libwifi-*.so* /usr/lib
sudo ldconfig

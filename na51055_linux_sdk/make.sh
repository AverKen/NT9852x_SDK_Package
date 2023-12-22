#!/bin/bash
source build/envsetup.sh
cd /home/vboxuser/Desktop/SDK_v2.05.009/NT9852x_SDK_Package/na51055_linux_sdk/code/application/source/uvc_cam/  
make ; make install

cd /home/vboxuser/Desktop/SDK_v2.05.009/NT9852x_SDK_Package/na51055_linux_sdk/
make rootfs;make pack

cd /home/vboxuser/123/SDcard/
rm FW98528A.bin

cd /home/vboxuser/Desktop/SDK_v2.05.009/NT9852x_SDK_Package/na51055_linux_sdk/output/packed
cp FW98528A.bin /home/vboxuser/123/SDcard/


#!/bin/bash
img_name=$1
copy_tmp_dir=$2
size=$3
CURPWD=$(pwd)

# 1. Generate raw fat32 image
dd if=/dev/zero of=$img_name bs=1M count=$size
mkfs.vfat $img_name
file_list="`ls $copy_tmp_dir | grep -v "\bEOF\b"`"
mkdir $CURPWD/bin/mnt

# for sdk_maker, use $SUDO_PWD to solving flow break on emmc-building
if [ -z ${SUDO_PWD} ]; then
	sudo mount -o loop $img_name bin/mnt
else
	echo "${SUDO_PWD}" | sudo -S PASSWD=${SUDO_PWD} mount -o loop $img_name bin/mnt
fi
if [ -z "$file_list" ]; then 
	echo -e "\e[1;33mRecovery partition is empty.\e[0m"
	pushd $copy_tmp_dir
	sudo cp EOF $CURPWD/bin/mnt
	popd
else
	echo -e "\e[1;33mRecovery partition will copy the following files:\e[0m\n$file_list"
	pushd $copy_tmp_dir
	sudo cp -r $file_list $CURPWD/bin/mnt
	sudo cp EOF $CURPWD/bin/mnt
	popd
fi
sudo umount bin/mnt

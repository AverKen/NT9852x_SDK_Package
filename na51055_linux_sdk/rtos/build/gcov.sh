#!/bin/bash
if [ -z ${LINUX_BUILD_TOP} ]; then
	echo "source build/envsetup.sh is required."
	exit 1
fi

MODEL=`echo $NVT_PRJCFG_MODEL_CFG | awk -F'/' '{print $(NF-1)}'`;

function make_gcov() {
	cd ${LINUX_BUILD_TOP}
	# modify kernel config to support gcov
	make linux_config_gcov
	if [ $? -ne 0 ]; then
		exit -1;
	fi;
	# make all
	make all
	if [ $? -ne 0 ]; then
		exit -1;
	fi;
	# etc symbolic created after make all
	# remove old export
	sed -i '/GCOV_PREFIX/d' ${ROOTFS_DIR}/rootfs/etc/profile
	# always create new
	echo "export GCOV_PREFIX=/mnt/sd/gcov"${HOME} >> ${ROOTFS_DIR}/rootfs/etc/profile
	echo "export GCOV_PREFIX_STRIP=2" >> ${ROOTFS_DIR}/rootfs/etc/profile
	echo -e "alias gcov_tar=\"cp -rf /sys/kernel/debug/gcov/home \${GCOV_PREFIX}/../../; cd /mnt/sd; tar -jcf gcov.tar.bz2 gcov; sync\"" >> ${ROOTFS_DIR}/rootfs/etc/profile
	# make rootfs and pack again
	make rootfs pack
	./build/rename_gcno.sh
}

function untar() {
	cd ${LINUX_BUILD_TOP}
	tar -jxvf gcov.tar.bz2;chmod -R 755 gcov/
	cp -avf gcov${LINUX_BUILD_TOP} ${LINUX_BUILD_TOP}/../
}

function gen_report_user() {
	rm -rf report_u
	lcov -c -d $1 -t ${MODEL} -o ${MODEL}.user.info --gcov-tool ${CROSS_COMPILE}gcov
	genhtml -o report_u ${MODEL}.user.info
}

function gen_report_kernel() {
	rm -rf report_k
	lcov -c -d $1 -b ${KERNELDIR} -t ${MODEL} -o ${MODEL}.kernel.info --gcov-tool ${CROSS_COMPILE}gcov
	genhtml -o report_k ${MODEL}.kernel.info
}

case $1 in
	make)
		make_gcov
	;;
	untar)
		untar
	;;
	genu)
		if [ -z $2 ]; then
			echo "usage: gcov genu [dir_to_source]"
			exit 1
		fi
		gen_report_user $2
	;;
	genk)
		if [ -z $2 ]; then
			echo "usage: gcov genk [dir_to_source]"
			exit 1
		fi
		gen_report_kernel $2
	;;
esac
for file in `find ${LINUX_BUILD_TOP}/code/hdal/ -name *tmp_*.gcno`
do
newfile=`echo ${file} | sed 's/.tmp_//g'`
echo $newfile
mv ${file} ${newfile}
done

#!/bin/sh

do_ZI_file() {
  FILE="$1"
  echo "File: $FILE"
  var2=${FILE::-7}:
  echo $var2  
  sed -e 's#^#'$var2'#' $FILE >> ZI.xls
}

do_RO_RW_file() {
  FILE="$1"
  echo "File: $FILE"
  var2=${FILE::-10}:
  echo $var2  
  sed -e 's#^#'$var2'#' $FILE >> RO_RW.xls
}
rm ZI.txt
rm RO_RW.txt
cd code/hdal
make codesize
for i in $(find . -name ZI.txt); do # Not recommended, will break on whitespace	
    do_ZI_file "$i"
done
for i in $(find . -name RO_RW.txt); do # Not recommended, will break on whitespace	
    do_RO_RW_file "$i"
done
sort -gr -o ../../ZI.txt -t: -k3 ZI.xls
rm ZI.xls
sort -gr -o ../../RO_RW.txt -t: -k3 RO_RW.xls
rm RO_RW.xls
cd ../..
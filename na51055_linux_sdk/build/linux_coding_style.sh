#!/bin/bash

tool_is_exist="`which astyle`"
if [ "$1" == "" ]; then
	echo "Help:"
	echo "$0 FileName"
	echo "e.g."
	echo -e "\t$0 hello_world.c"
	exit -1;
fi

if [ "$tool_is_exist" != "" ]; then
	astyle -A3 -T -K -w -p -U -k3 -j -c --mode=c -n -z2 -m0 -H $1
	ret=$?
	exit $ret
else
	echo "without astyle tool"
fi

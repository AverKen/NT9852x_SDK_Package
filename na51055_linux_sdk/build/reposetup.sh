#!/bin/bash

if [ -f ${PWD}/build/envsetup.sh ]; then
	python3 build/nvt-tools/repo_setup.py ../.repo
else
	echo "Can't support execute env setup on ${PWD}"
fi

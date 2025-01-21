#!/bin/bash

python3 ./primes-cli.py $*
if [ $? != 0 ]; then exit $?; else exit 0; fi

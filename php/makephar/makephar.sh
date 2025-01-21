#!/bin/zsh
php --define phar.readonly=0 ${0:a}".php" ${PWD}

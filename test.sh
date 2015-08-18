#!/usr/bin/env bash 
set -x #Pring every line of commands out
exec 1> >( tools/outfilter.py -v -o ~/test.log ) 2>&1
SWIFT_DIR=~
source ./tools/ini-config
iniset ~/test.log DEFAULT user stack
iniset ~/test.log DEFAULT devices "$SWIFT_DIR"
iniset ~/test.log DEFAULT mount_check false
iniset ~/test.log DEFAULT pipeline "healthcheck account-server"
iniset ~/test.log app:object-server use egg:kinetic_swift#obj

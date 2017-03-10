#!/bin/bash
#set -eu
# assumptions:
# network external flat is created
# clone benchmarling repo to /opt/benchmarking_live-migration and edit credentrials.json


# setup environment for lvm
#./setup_lvm_environment.sh

# start the testing of live migration
./test_lv_environment.sh

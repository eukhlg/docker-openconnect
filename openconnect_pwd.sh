#!/bin/sh
FLAG=$1
VALUE=$2
yes ${USER_PASSWORD} | head -n 3 | openconnect ${FLAG} ${VALUE}
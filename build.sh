#!/bin/bash
# Build from WSL with the Windows SDK.
# Usage: ./build.sh [-t]        -> build/Car.prg   (-t = include unit tests)
#        ./build.sh sail [-t]   -> build/Sail.prg
set -e
C=/mnt/c/Users/marce/AppData/Roaming/Garmin
S=$(ls -d $C/ConnectIQ/Sdks/connectiq-sdk-win-* | tail -1)
H=/tmp/ciqhome; mkdir -p $H; ln -sfn $C $H/.Garmin  # Linux compiler reads devices from ~/.Garmin/ConnectIQ
cd "$(dirname "$0")"; mkdir -p build
SRC=.; OUT=Car
if [ "$1" = sail ]; then SRC=sail; OUT=Sail; shift; fi
java -Xms1g -Duser.home=$H -Dfile.encoding=UTF-8 -cp $S/bin/monkeybrains.jar com.garmin.monkeybrains.Monkeybrains \
  -f $SRC/monkey.jungle -o build/$OUT.prg -y $C/ConnectIQ/developer_key.der -d fr955 -w "$@"

#!/bin/bash
# Build from WSL with the Windows SDK. Usage: ./build.sh [-t]   (-t = include unit tests)
set -e
C=/mnt/c/Users/marce/AppData/Roaming/Garmin
S=$(ls -d $C/ConnectIQ/Sdks/connectiq-sdk-win-* | tail -1)
H=/tmp/ciqhome; mkdir -p $H; ln -sfn $C $H/.Garmin  # Linux compiler reads devices from ~/.Garmin/ConnectIQ
cd "$(dirname "$0")"; mkdir -p build
java -Xms1g -Duser.home=$H -Dfile.encoding=UTF-8 -cp $S/bin/monkeybrains.jar com.garmin.monkeybrains.Monkeybrains \
  -f monkey.jungle -o build/Car.prg -y $C/ConnectIQ/developer_key.der -d fr955 -w "$@"

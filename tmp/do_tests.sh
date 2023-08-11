#!/bin/sh

FILES=build/riscv-tests-hex/rv32*i-p-*
for f in $FILES
do
    FILE_NAME="${f##*/}"
    #MODULE_NAME=$FILE_NAME | cut -c '1-{${#FILE_NAME}}'
    COUNT=${#FILE_NAME}
    NCOUNT=$((COUNT-4))
    MODULE_NAME=`echo $FILE_NAME | cut -c 1-$NCOUNT`
    sed "s/parameter memory_hex =.*/parameter memory_hex = \"build\/$FILE_NAME\";/g" startup.v > "$MODULE_NAME.v"
    iverilog -v $MODULE_NAME.v -s startup -o build/org/$MODULE_NAME
    ./build/org/$MODULE_NAME
done
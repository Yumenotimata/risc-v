#!/bin/sh

FILES=riscv-tests-hex/rv32*i-p-*
for f in $FILES
do
    FILE_NAME="${f##*/}"
    
    sed "s/parameter memory_hex =.*/parameter memory_hex = \"build\/$FILE_NAME\"/g" ../startup.v > "$FILE_NAME.v"
    iverilog -v $FILE_NAME.v -s $FILE_NAME -o /org/$FILE_NAME
done
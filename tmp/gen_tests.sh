#!/bin/bash

FILES=/src/target/share/riscv-tests/isa/rv32*i-p-*
SAVE_DIR=/src/mytests

for f in $FILES
do
    FILE_NAME="${f##*/}"
    if [[ ! $f =~ "dump" ]]; then
        riscv64-unknown-else-objcopy -O binary $f $SAVE_DIR/$FILE_NAME.bin
        od -An -tx1 -w1 -v $SAVE_DIR/$FILE_NAME.bin > $SAVE_DIR/$FILE_NAME.bin
        rm -f $SAVE_DIR/$FILE_NAME.bin
    fi
done
s/parameter memory_hex =.*/parameter memory_hex = test/g" ../.
./startup.v > tmp
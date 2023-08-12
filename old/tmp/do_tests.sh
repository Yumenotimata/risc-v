#!/bin/sh

FILES=build/riscv-tests-hex/rv32*i-p-*
for f in $FILES
do
    FILE_NAME="${f##*/}"
    #MODULE_NAME=$FILE_NAME | cut -c '1-{${#FILE_NAME}}'
    COUNT=${#FILE_NAME}
    NCOUNT=$((COUNT-4))
    MODULE_NAME=`echo $FILE_NAME | cut -c 1-$NCOUNT`
    sed "s/parameter memory_hex =.*/parameter memory_hex = \"build\/riscv-tests-hex\/$FILE_NAME\";/g" startup.v > "$MODULE_NAME.v"
    sed -i "s/\$dumpfile(.*/\$dumpfile(\"vcd\/$MODULE_NAME.vcd\");/g" $MODULE_NAME.v
    sed -i "s/\parameter result_file_path =.*/parameter result_file_path = \"result\/$MODULE_NAME.txt\";/g" $MODULE_NAME.v
    echo iverilog -v $MODULE_NAME.v -s startup -o build/org/$MODULE_NAME
    iverilog -v $MODULE_NAME.v -s startup -o build/org/$MODULE_NAME
    ./build/org/$MODULE_NAME
    touch result/$MODULE_NAME.txt
done

cp /dev/null result/unpassed_tests.txt
cp /dev/null result/passed_tests.txt
grep -ril "failed" result >> result/unpassed_tests.txt
grep -ril "passed" result >> result/passed_tests.txt
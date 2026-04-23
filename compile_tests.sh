#!/bin/bash
set -e

# Core test pool for checking hardware functionality
TESTS="master_test"

for TEST in $TESTS; do
    echo "Compiling $TEST..."
    riscv64-elf-gcc -O2 -march=rv32i -mabi=ilp32 -ffreestanding -nostdlib -T src/c_tests/link.ld -o src/c_tests/$TEST.elf src/c_tests/start.S src/c_tests/$TEST.c
    riscv64-elf-objcopy -O binary src/c_tests/$TEST.elf src/c_tests/$TEST.bin
    python3 src/c_tests/bin2hex.py src/c_tests/$TEST.bin src/c_tests/$TEST.hex
    riscv64-elf-objdump -b binary -m riscv:rv32 -D src/c_tests/$TEST.bin > src/c_tests/$TEST.dump
done

# Loop and run Verilator test assertions for ALL binaries
echo "Testing..."
for TEST in $TESTS; do
    echo "[TESTING] Staging $TEST..."
    cp src/c_tests/$TEST.hex program.hex
    cp program.hex program_data.hex
    
    # Supress massive output, fail aggressively if not 42!
    if ! make -f Makefile.cocotb EXTRA_ARGS="-Wno-CASEINCOMPLETE -Wno-WIDTH" > src/c_tests/${TEST}_sim.log 2>&1; then
        echo -e "[1;31m[FAILED] $TEST failed assertion![0m"
        exit 1
    else
        echo -e "[1;32m[PASSED] $TEST execution success.[0m"
    fi
done

echo "SUCCESS! All instructions mapped in processor executed perfectly!"

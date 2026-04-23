// master_test.c
// Fits within the 512 byte limit

volatile int global_var = 777; // Tests AUIPC/LUI

int __attribute__((noinline)) subroutine(int a, int b) {
    // Tests JAL/JALR and stack framing
    return a + b + global_var; 
}

int main() {
    volatile int passed = 1;
    volatile int a = 15;
    volatile int b = 5;
    
    // 1. ALU Operations
    if (a + b != 20) passed = 0;  // ADD
    if (a - b != 10) passed = 0;  // SUB
    if ((a & b) != 5) passed = 0;  // AND
    if ((a | b) != 15) passed = 0; // OR
    if (a << 2 != 60) passed = 0;  // SLL
    
    // 2. Branches
    if (a == b) passed = 0; // BEQ
    if (a <= b) passed = 0; // BLE
    
    // 3. Memory 
    volatile signed char bytes[4] = {-10, 20, 0, 0};
    volatile short halfwords[2] = {-1000, 2000};
    
    if (bytes[0] != -10) passed = 0;
    if (bytes[1] != 20) passed = 0;
    if (halfwords[0] != -1000) passed = 0;
    if (halfwords[1] != 2000) passed = 0;
    
    bytes[2] = 50;
    if (bytes[2] != 50) passed = 0;
    
    halfwords[1] = 3000;
    if (halfwords[1] != 3000) passed = 0;

    // 4. Subroutine Call
    if (subroutine(a, b) != 797) passed = 0;
    
    return passed ? 42 : 0;
}
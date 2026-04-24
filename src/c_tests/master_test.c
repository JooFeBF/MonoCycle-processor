// master_test.c
// Fits within the 512 byte limit

volatile int global_var = 777; // Tests AUIPC/LUI

int __attribute__((noinline)) subroutine(int a, int b) {
    // Tests JAL/JALR and stack framing
    return a + b + global_var; 
}

int main() {
    volatile int a = 15;
    volatile int b = 5;
    
    // 1. ALU Operations
    if (a + b != 20) return 1;  // ADD
    if (a - b != 10) return 2;  // SUB
    if ((a & b) != 5) return 3;  // AND
    if ((a | b) != 15) return 4; // OR
    if (a << 2 != 60) return 5;  // SLL
    
    // 2. Branches
    if (a == b) return 6; // BEQ
    if (a <= b) return 7; // BLE
    
    // 3. Memory 
    volatile signed char bytes[4] = {-10, 20, 0, 0};
    volatile short halfwords[2] = {-1000, 2000};
    
    if (bytes[0] != -10) return 8;
    if (bytes[1] != 20) return 9;
    if (halfwords[0] != -1000) return 10;
    if (halfwords[1] != 2000) return 11;
    
    bytes[2] = 50;
    if (bytes[2] != 50) return 12;
    
    halfwords[1] = 3000;
    if (halfwords[1] != 3000) return 13;

    // 4. Subroutine Call
    if (subroutine(a, b) != 797) return 14;
    
    return 42;
}
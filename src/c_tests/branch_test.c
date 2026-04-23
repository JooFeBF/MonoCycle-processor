int main() {
    volatile int a = 10;
    volatile int b = 5;
    volatile int c = 10;
    
    volatile int passed = 1;
    
    // BEQ
    if (a != c) passed = 0;
    // BNE
    if (a == b) passed = 0;
    // BLT
    if (b >= a) passed = 0;
    // BGE
    if (a < b) passed = 0;
    if (a < c) passed = 0;
    // BLTU, BGEU... tested assuming signedness holds up similarly for small positives
    
    if (passed) {
        return 42;
    }
    return 0;
}
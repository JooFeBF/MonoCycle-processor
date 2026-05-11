// Stack integrity test

volatile int canary = 0xDEAD;
volatile int depth = 0;

int __attribute__((noinline)) safe_recursive(int n) {
    volatile int local_check = 0xBEEF;
    depth++;
    
    if (canary != 0xDEAD) {
        depth--;
        return -1; // Global corruption
    }
    
    if (n <= 0 || depth >= 12) {
        if (local_check != 0xBEEF) {
            depth--;
            return -2; // Local corruption
        }
        depth--;
        return 50;
    }
    
    int result = safe_recursive(n - 1) + 1;
    
    if (local_check != 0xBEEF) {
        depth--;
        return -2;
    }
    
    depth--;
    return result;
}

int main() {
    depth = 0;
    
    if (canary != 0xDEAD) return 1;
    
    int result = safe_recursive(8);
    if (result < 0) return 2;
    if (result < 50) return 3;
    
    if (canary != 0xDEAD) return 4;
    if (depth != 0) return 5;
    
    return 42;
}
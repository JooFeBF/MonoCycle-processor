// Simple fibonacci test - iterative version to save space
int main() {
    volatile int n = 6; // Calculate fib(6) = 8
    volatile int a = 0, b = 1, c = 0;
    
    // Handle base cases
    if (n <= 1) return 42; // fib(0)=0, fib(1)=1
    
    // Iterative fibonacci
    for (volatile int i = 2; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    
    // fib(6) should be 8
    if (c == 8) {
        return 42; // Success code
    } else {
        return 1;  // Error code
    }
}
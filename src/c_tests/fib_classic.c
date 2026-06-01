// Classic Fibonacci sequence calculator
// Calculates the 10th Fibonacci number (55)

int __attribute__((noinline)) fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main() {
    int result = fibonacci(10);  // 10th Fibonacci number = 55
    
    // Test if result is correct
    if (result == 55) {
        return 42;  // Success
    }
    
    return 1;  // Failure
}
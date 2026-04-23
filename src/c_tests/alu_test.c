int main() {
    volatile int a = 15;
    volatile int b = 5;
    volatile int sum = a + b;
    volatile int sub = a - b;
    volatile int an = a & b;
    volatile int or = a | b;
    volatile int xor = a ^ b;
    volatile int sll = a << 2;
    volatile int srl = a >> 2;
    volatile int slt = (a < b) ? 1 : 0;
    
    if (sum == 20 && sub == 10 && an == 5 && or == 15 && xor == 10 && sll == 60 && srl == 3 && slt == 0) {
        return 42; // Success
    }
    return 0; // Fail
}
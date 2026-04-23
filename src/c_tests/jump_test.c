int __attribute__((noinline)) funcB(int arg) {
    return arg + 777;
}

int __attribute__((noinline)) funcA(int x) {
    // Function pointers heavily exercise JALR
    int (*fp)(int) = &funcB;
    return fp(x) * 2;
}

int main() {
    volatile int passed = 1;
    
    // Test base JAL + JALR pipeline
    int result = funcA(15);
    
    // (15 + 777) * 2 = 792 * 2 = 1584
    if (result != 1584) passed = 0;


    return passed ? 42 : 0;
}

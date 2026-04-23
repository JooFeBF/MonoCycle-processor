int main() {
    volatile int array[4] = {10, 20, 30, 40};
    volatile int passed = 1;
    
    if (array[0] != 10) passed = 0;
    if (array[1] != 20) passed = 0;
    if (array[2] != 30) passed = 0;
    if (array[3] != 40) passed = 0;
    
    array[0] = 50;
    if (array[0] != 50) passed = 0;
    
    if (passed) {
        return 42;
    }
    return 0;
}
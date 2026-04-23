#include <stdint.h>

int main() {
    volatile int passed = 1;
    
    volatile int8_t b_signed = -10;
    volatile uint8_t b_unsigned = 200;
    
    volatile int16_t h_signed = -1000;
    volatile uint16_t h_unsigned = 40000;
    
    if (b_signed != -10) passed = 0;
    if (b_unsigned != 200) passed = 0;
    
    if (h_signed != -1000) passed = 0;
    if (h_unsigned != 40000) passed = 0;

    // test stores implicitly by overwriting
    b_signed = 50;
    if (b_signed != 50) passed = 0;
    
    h_signed = 3000;
    if (h_signed != 3000) passed = 0;

    return passed ? 42 : 0;
}

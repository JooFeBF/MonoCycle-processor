int main() {
    volatile int passed = 1;
    volatile int neg = -16;          // 0xFFFFFFF0
    volatile unsigned int uneg = -16; // 0xFFFFFFF0
    
    // sra (Arithmetic Shift Right -> preserves sign bit)
    volatile int sra_res = neg >> 2; 
    if (sra_res != -4) passed = 0; // 0xFFFFFFFC
    
    // srl (Logical Shift Right -> pads left with zeros)
    volatile unsigned int srl_res = uneg >> 2;
    if (srl_res != 1073741820) passed = 0; // 0x3FFFFFFC
    
    // sltu (Set Less Than Unsigned)
    volatile unsigned int a = 5;
    volatile unsigned int b = 4294967295U; // 0xFFFFFFFF (uneg as -1 essentially)
    
    // As unsigned, 5 is deeply less than 0xFFFFFFFF. 
    // Structurally 'b' looks like a negative number bitwise, so signed SLT would fail.
    if (!(a < b)) passed = 0; 
    
    // Also test unsigned branches explicitly
    // bltu vs bgeu
    if (a >= b) passed = 0; 
    if (b < a) passed = 0;

    return passed ? 42 : 0;
}

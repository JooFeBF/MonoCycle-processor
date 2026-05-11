// Mini recursive test

volatile int depth = 0;

int __attribute__((noinline)) sum_down(int n) {
    depth++;
    if (n <= 0) {
        depth--;
        return 0;
    }
    int result = n + sum_down(n - 1);
    depth--;
    return result;
}

int __attribute__((noinline)) ping(int n);
int __attribute__((noinline)) pong(int n);

int __attribute__((noinline)) ping(int n) {
    depth++;
    if (n <= 0) {
        depth--;
        return 0;
    }
    int result = pong(n - 1) + 1;
    depth--;
    return result;
}

int __attribute__((noinline)) pong(int n) {
    depth++;
    if (n <= 0) {
        depth--;
        return 0;
    }
    int result = ping(n - 1) + 1;
    depth--;
    return result;
}

int __attribute__((noinline)) deep(int n) {
    depth++;
    if (depth > 15 || n <= 0) {
        depth--;
        return 10;
    }
    int result = deep(n - 1) + 1;
    depth--;
    return result;
}

int main() {
    depth = 0;
    
    if (sum_down(3) != 6) return 1;
    depth = 0;
    
    if (ping(4) != 4) return 2;
    depth = 0;
    
    if (deep(8) != 18) return 3;
    depth = 0;
    
    if (depth != 0) return 4;
    
    return 42;
}
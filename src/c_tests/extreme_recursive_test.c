// Edge case recursion test

volatile int depth = 0;

int __attribute__((noinline)) very_deep(int n) {
    depth++;
    if (depth >= 25 || n <= 0) {
        depth--;
        return 50;
    }
    int result = very_deep(n - 1) + 1;
    depth--;
    return result;
}

int __attribute__((noinline)) chain_x(int n);
int __attribute__((noinline)) chain_y(int n);

int __attribute__((noinline)) chain_x(int n) {
    depth++;
    if (depth >= 12 || n <= 0) {
        depth--;
        return 1;
    }
    int result = chain_y(n - 1) + 1;
    depth--;
    return result;
}

int __attribute__((noinline)) chain_y(int n) {
    depth++;
    if (depth >= 12 || n <= 0) {
        depth--;
        return 2;
    }
    int result = chain_x(n - 1) + 1;
    depth--;
    return result;
}

int main() {
    if (very_deep(20) < 60) return 1;
    depth = 0;
    if (chain_x(6) < 5) return 2;
    depth = 0;
    if (depth != 0) return 3;
    return 42;
}
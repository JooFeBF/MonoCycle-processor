import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: bin2hex.py <input.bin> <output.hex>")
        sys.exit(1)

    in_file = sys.argv[1]
    out_file = sys.argv[2]

    with open(in_file, "rb") as f:
        data = f.read()

    # Pad data to multiple of 4 bytes
    rem = len(data) % 4
    if rem != 0:
        data += b'\x00' * (4 - rem)

    with open(out_file, "w") as f:
        for i in range(0, len(data), 4):
            word = int.from_bytes(data[i:i+4], byteorder='little')
            f.write(f"{word:08x}\n")

if __name__ == "__main__":
    main()

import os
import sys
from PIL import Image, ImageDraw, ImageFont

CHAR_W = 8
CHAR_H = 16
NUM_CHARS = 256
OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "src", "vga_font.hex"
)
FONT_CANDIDATES = [
    ("/usr/share/fonts/TTF/JetBrainsMonoNLNerdFont-Regular.ttf", 13, 0),
    ("/usr/share/fonts/TTF/JetBrainsMonoNLNerdFontMono-Regular.ttf", 13, 0),
    ("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf", 13, 0),
    ("/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf", 13, 0),
    ("/usr/share/fonts/liberation/LiberationMono-Regular.ttf", 13, 0),
    ("/usr/share/fonts/noto/NotoSansMono-Regular.ttf", 12, 0),
    ("/usr/share/fonts/noto/NotoSansMono-Medium.ttf", 12, 0),
    ("/usr/share/fonts/gnu-free/FreeMono.otf", 14, 0),
]


def find_font():
    for path, size, y_tweak in FONT_CANDIDATES:
        if os.path.isfile(path):
            print(f"Using font: {path} (size={size}, y_tweak={y_tweak})")
            return ImageFont.truetype(path, size), y_tweak, size
    print("WARNING: No suitable font found, using Pillow default (low quality)")
    return ImageFont.load_default(), 0, 10


def compute_baseline(font):
    ref_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    ascent, descent = font.getmetrics()
    total_height = ascent + descent
    y_offset = (CHAR_H - total_height) // 2
    print(f"  Font metrics: ascent={ascent}, descent={descent}, total={total_height}")
    print(f"  Computed y_offset: {y_offset}")
    return y_offset


def render_char(char, font, y_offset):
    RENDER_W = 32
    RENDER_H = 32
    img = Image.new("L", (RENDER_W, RENDER_H), 0)
    draw = ImageDraw.Draw(img)
    bbox = font.getbbox(char)
    if bbox is None:
        return [0] * CHAR_H
    glyph_w = bbox[2] - bbox[0]
    x = (CHAR_W - glyph_w) // 2 - bbox[0]
    y = y_offset
    draw.text((x, y), char, fill=255, font=font)
    pixels = img.load()
    rows = []
    for row in range(CHAR_H):
        byte_val = 0
        for col in range(CHAR_W):
            if pixels[col, row] > 127:
                byte_val |= 1 << (7 - col)
        rows.append(byte_val)
    return rows


def generate_font():
    font, y_tweak, size = find_font()
    y_offset = compute_baseline(font) + y_tweak
    test_rows = render_char("A", font, y_offset)
    first_nz = next((i for i, b in enumerate(test_rows) if b != 0), -1)
    last_nz = next((i for i in range(CHAR_H - 1, -1, -1) if test_rows[i] != 0), -1)
    print(f"  'A' test: first_nz={first_nz}, last_nz={last_nz}")
    if first_nz >= 0 and first_nz < 1:
        adjust = 1 - first_nz
        y_offset += adjust
        print(f"  Adjusting y_offset by +{adjust} to push glyph down")
    elif last_nz >= 0 and last_nz > 13:
        adjust = last_nz - 13
        y_offset -= adjust
        print(f"  Adjusting y_offset by -{adjust} to push glyph up")
    print(f"  Final y_offset: {y_offset}")
    table = []
    for code in range(NUM_CHARS):
        if 32 <= code <= 126:
            char = chr(code)
            rows = render_char(char, font, y_offset)
        else:
            rows = [0] * CHAR_H
        table.extend(rows)
    assert (
        len(table) == NUM_CHARS * CHAR_H
    ), f"Expected {NUM_CHARS * CHAR_H}, got {len(table)}"
    return table


def dump_char(table, code):
    start = code * CHAR_H
    char = chr(code) if 32 <= code <= 126 else "?"
    print(f"  Character '{char}' (0x{code:02X}, lines {start}-{start+CHAR_H-1}):")
    for row in range(CHAR_H):
        byte_val = table[start + row]
        bits = f"{byte_val:08b}".replace("0", ".").replace("1", "#")
        print(f"    {byte_val:02X}  {bits}")
    print()


def main():
    table = generate_font()
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        for byte_val in table:
            f.write(f"{byte_val:02X}\n")
    print(f"\nWrote {len(table)} lines to {OUTPUT_PATH}")
    print("\n--- Verification ---")
    print(f"Total lines: {len(table)} (expected {NUM_CHARS * CHAR_H})")
    space_start = 32 * CHAR_H
    space_rows = table[space_start : space_start + CHAR_H]
    space_ok = all(b == 0 for b in space_rows)
    print(f"Space (0x20) all zeros: {'OK' if space_ok else 'FAIL'}")
    a_start = 65 * CHAR_H
    a_rows = table[a_start : a_start + CHAR_H]
    a_nonzero = sum(1 for b in a_rows if b != 0)
    print(f"'A' (0x41) non-zero rows: {a_nonzero} (should be ~8-11)")
    print("\n--- Sample Glyphs ---")
    for code in [
        ord(" "),
        ord("A"),
        ord("B"),
        ord("M"),
        ord("W"),
        ord("0"),
        ord("1"),
        ord("x"),
        ord(":"),
        ord("i"),
        ord("."),
        ord("|"),
        ord("@"),
        ord("g"),
        ord("y"),
        ord("_"),
        ord("~"),
        ord("#"),
    ]:
        dump_char(table, code)


if __name__ == "__main__":
    main()

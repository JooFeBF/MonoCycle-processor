import sys
from PIL import Image, ImageDraw, ImageFont

try:
    img_font = ImageFont.truetype("DejaVuSansMono.ttf", 16)
except:
    img_font = ImageFont.load_default()

with open("src/vga_font.hex", "w") as f:
    for i in range(256):
        img = Image.new('1', (8, 16), color=0)
        draw = ImageDraw.Draw(img)
        char = chr(i) if 32 <= i < 127 else ' '
        draw.text((0, -2), char, font=img_font, fill=1)
        for y in range(16):
            val = 0
            for x in range(8):
                if img.getpixel((x, y)):
                    val |= (1 << (7 - x))
            f.write(f"{val:02x}\n")

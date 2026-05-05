from PIL import Image, ImageDraw, ImageFont
import os

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# Magento-ish palette
ORANGE = (240, 80, 40, 255)
DARK   = (30, 30, 40, 255)
WHITE  = (255, 255, 255, 255)


def make(size: int, path: str):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded square background with vertical gradient (orange -> deep orange)
    radius = max(2, size // 5)
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / max(1, size - 1)
        r = int(245 + (200 - 245) * t)
        g = int(110 + (60 - 110) * t)
        b = int(30 + (20 - 30) * t)
        bd.line([(0, y), (size, y)], fill=(r, g, b, 255))
    # mask to rounded rect
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    img.paste(bg, (0, 0), mask)

    # Draw an "M" letter centered
    try:
        # try a bold-ish system font
        for candidate in [
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        ]:
            if os.path.exists(candidate):
                font = ImageFont.truetype(candidate, int(size * 0.66))
                break
        else:
            font = ImageFont.load_default()
    except Exception:
        font = ImageFont.load_default()

    text = "M"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1] - size * 0.02

    # subtle shadow
    d.text((tx + max(1, size // 32), ty + max(1, size // 32)), text, font=font, fill=(0, 0, 0, 110))
    # main letter
    d.text((tx, ty), text, font=font, fill=WHITE)

    # small accent dot bottom-right (the "hint" dot)
    dot_r = max(2, size // 8)
    cx, cy = size - dot_r - max(1, size // 14), size - dot_r - max(1, size // 14)
    d.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=DARK)
    d.ellipse(
        [cx - dot_r // 2, cy - dot_r // 2, cx + dot_r // 2, cy + dot_r // 2],
        fill=(255, 220, 80, 255),
    )

    img.save(path, "PNG")


for s in (16, 32, 48, 128):
    make(s, os.path.join(OUT_DIR, f"icon{s}.png"))

# keep a default icon.png = 128
make(128, os.path.join(OUT_DIR, "icon.png"))
print("done")

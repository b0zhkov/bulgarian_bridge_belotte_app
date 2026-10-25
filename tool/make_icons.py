"""Draws the app icon (web/PWA set) in the app's style: black background,
a red patterned card back fanned behind a white card face with the rank and
a vector spade, the same shapes the game draws.

Run: python3 tool/make_icons.py  -> web/icons/*.png, web/favicon.png
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), '..')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Comfortaa-Regular.ttf')
BG = (0, 0, 0, 255)
FACE = (255, 255, 255, 255)
INK = (17, 17, 17, 255)
BACK = (242, 85, 74, 255)
LINE = (255, 255, 255, 102)
S = 2048  # master size (downscaled with Lanczos)


def bez3(p0, p1, p2, p3, n=24):
    return [
        (
            (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0],
            (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1],
        )
        for t in (i / n for i in range(n + 1))
    ]


def bez2(p0, p1, p2, n=16):
    return [
        ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
         (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1])
        for t in (i / n for i in range(n + 1))
    ]


def heart():
    c = [((0.5, 0.92), (0.30, 0.74), (0.04, 0.58), (0.04, 0.33)),
         ((0.04, 0.33), (0.04, 0.16), (0.17, 0.05), (0.30, 0.05)),
         ((0.30, 0.05), (0.40, 0.05), (0.47, 0.11), (0.5, 0.19)),
         ((0.5, 0.19), (0.53, 0.11), (0.60, 0.05), (0.70, 0.05)),
         ((0.70, 0.05), (0.83, 0.05), (0.96, 0.16), (0.96, 0.33)),
         ((0.96, 0.33), (0.96, 0.58), (0.70, 0.74), (0.5, 0.92))]
    pts = []
    for seg in c:
        pts += bez3(*seg)
    return pts


def spade():
    """Unit-square spade as in SuitIcon: flipped heart body + stem."""
    body = [(0.04 + x * 0.92, -0.06 + (1 - y) * 0.92) for x, y in heart()]
    stem = bez2((0.5, 0.55), (0.52, 0.85), (0.70, 0.98)) + \
        bez2((0.30, 0.98), (0.48, 0.85), (0.5, 0.55))
    return body, stem


def card_layer(w, h, face):
    """A card image (w x h) with rounded corners."""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(w * 0.16)
    if face:
        d.rounded_rectangle([0, 0, w - 1, h - 1], r, fill=FACE)
        font = ImageFont.truetype(FONT, int(w * 0.46))
        d.text((w * 0.14, w * 0.04), 'A', font=font, fill=INK)
        size = w * 0.42
        ox, oy = w * 0.13, h - w * 0.13 - size
        body, stem = spade()
        for poly in (body, stem):
            d.polygon([(ox + x * size, oy + y * size) for x, y in poly], fill=INK)
    else:
        bw = max(2, int(w * 0.045))
        d.rounded_rectangle([0, 0, w - 1, h - 1], r, fill=(255, 255, 255, 255))
        d.rounded_rectangle([bw, bw, w - 1 - bw, h - 1 - bw], r - bw, fill=BACK)
        # Concentric rings and a dashed centre, like CardBackPainter.
        ov = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        o = ImageDraw.Draw(ov)
        cx, cy = w / 2, h / 2
        lw = max(1, int(w * 0.025))
        for k in (0.18, 0.30, 0.42):
            rr = w * k
            o.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=LINE, width=lw)
        for i in range(12):
            a = i * math.pi / 6
            o.line([(cx + math.cos(a) * w * 0.05, cy + math.sin(a) * w * 0.05),
                    (cx + math.cos(a) * w * 0.10, cy + math.sin(a) * w * 0.10)],
                   fill=LINE, width=lw)
        mask = Image.new('L', (w, h), 0)
        ImageDraw.Draw(mask).rounded_rectangle([bw, bw, w - 1 - bw, h - 1 - bw], r - bw, fill=255)
        img.paste(ov, (0, 0), Image.composite(ov, Image.new('RGBA', (w, h)), mask).split()[3])
    return img


def master(content_scale, rounded):
    """Full icon at S x S. content_scale shrinks the artwork (maskable safe
    zone); rounded draws a rounded black tile on transparency."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if rounded:
        d.rounded_rectangle([0, 0, S - 1, S - 1], int(S * 0.22), fill=BG)
    else:
        d.rectangle([0, 0, S, S], fill=BG)
    cw = int(S * 0.40 * content_scale)
    ch = int(cw * 1.4)
    for face, angle, dx in ((False, 14, -0.13), (True, -8, 0.10)):
        card = card_layer(cw, ch, face)
        # Soft shadow.
        sh = Image.new('RGBA', card.size, (0, 0, 0, 0))
        sh.putalpha(card.split()[3].point(lambda a: a * 0.45))
        card_r = card.rotate(angle, resample=Image.BICUBIC, expand=True)
        sh_r = sh.rotate(angle, resample=Image.BICUBIC, expand=True)
        x = int(S / 2 + dx * S * content_scale - card_r.width / 2)
        y = int(S / 2 - card_r.height / 2 + S * 0.02 * content_scale)
        img.alpha_composite(sh_r, (x, y + int(S * 0.012)))
        img.alpha_composite(card_r, (x, y))
    return img


def save(img, path, size, flatten=False):
    out = img.resize((size, size), Image.LANCZOS)
    if flatten:
        bg = Image.new('RGBA', out.size, BG)
        bg.alpha_composite(out)
        out = bg.convert('RGB')
    out.save(os.path.join(ROOT, path), optimize=True)


if __name__ == '__main__':
    tile = master(1.0, rounded=True)
    full = master(1.0, rounded=False)
    safe = master(0.78, rounded=False)  # maskable: art inside the 80% circle
    save(tile, 'web/icons/Icon-192.png', 192)
    save(tile, 'web/icons/Icon-512.png', 512)
    save(safe, 'web/icons/Icon-maskable-192.png', 192, flatten=True)
    save(safe, 'web/icons/Icon-maskable-512.png', 512, flatten=True)
    save(full, 'web/icons/apple-touch-icon.png', 180, flatten=True)
    save(tile, 'web/favicon.png', 48)

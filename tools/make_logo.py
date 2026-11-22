"""Draws JunkAway's project logo (a stuffed bag tossing out a piece of grey
junk) to media/logo.png. Original artwork, no game assets.

    python tools/make_logo.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
W = 400 * S

img = Image.new("RGB", (W, W), (22, 28, 34))
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.06, W * 0.1, W * 0.94, W * 0.98), fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(70 * S))
img.paste(Image.new("RGB", (W, W), (64, 82, 92)), (0, 0), glow)
d = ImageDraw.Draw(img)


def p(x, y):
    return (x * S, y * S)


# The bag: a round leather body, a gathered neck and a tie.
d.ellipse([p(70, 150), p(290, 360)], fill=(92, 56, 30))
d.ellipse([p(84, 162), p(276, 346)], fill=(138, 86, 46))
d.ellipse([p(104, 176), p(214, 270)], fill=(160, 104, 58))  # light on the leather
d.polygon([p(130, 168), p(150, 120), p(210, 120), p(230, 168)], fill=(128, 78, 40))
d.polygon([p(140, 126), p(126, 98), p(156, 110), p(180, 94), p(204, 110), p(234, 98), p(220, 126)],
          fill=(150, 96, 52))
d.rounded_rectangle([p(134, 140), p(226, 156)], radius=6 * S, fill=(214, 180, 96))
for x in (150, 180, 210):  # stitches
    d.line([p(x - 40, 300), p(x - 30, 310)], fill=(92, 56, 30), width=3 * S)
    d.line([p(x + 20, 300), p(x + 30, 310)], fill=(92, 56, 30), width=3 * S)

# A curved arrow from the bag's mouth out to the right.
cx, cy, r = 250, 150, 70
pts = [p(cx + r * math.cos(math.radians(a)), cy - r * math.sin(math.radians(a))) for a in range(170, 15, -5)]
d.line(pts, fill=(236, 226, 196), width=12 * S, joint="curve")
ex, ey = cx + r * math.cos(math.radians(15)), cy - r * math.sin(math.radians(15))
d.polygon([p(ex + 22, ey + 4), p(ex - 14, ey - 18), p(ex - 6, ey + 24)], fill=(236, 226, 196))

# The junk: a cracked grey pot flying out.
jx, jy = 318, 232
d.ellipse([p(jx - 34, jy - 26), p(jx + 34, jy + 36)], fill=(96, 100, 104))
d.ellipse([p(jx - 28, jy - 20), p(jx + 26, jy + 28)], fill=(132, 136, 140))
d.rectangle([p(jx - 14, jy - 40), p(jx + 14, jy - 22)], fill=(110, 114, 118))
d.line([p(jx - 6, jy - 14), p(jx + 4, jy + 2), p(jx - 4, jy + 14)], fill=(70, 72, 76), width=4 * S)
for dx, dy in ((48, -8), (54, 14), (44, 34)):  # motion marks
    d.line([p(jx + dx, jy + dy), p(jx + dx + 22, jy + dy)], fill=(200, 210, 214), width=4 * S)

vig = Image.new("L", (W, W), 0)
ImageDraw.Draw(vig).ellipse((-W * 0.15, -W * 0.15, W * 1.15, W * 1.15), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(50 * S))
img = Image.composite(img, Image.new("RGB", (W, W), (10, 12, 14)), vig)

out = os.path.join(os.path.dirname(__file__), "..", "media", "logo.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
img.resize((400, 400), Image.LANCZOS).save(out)
print(out)

"""Renders the animated itch.io theme images for HYPERDASH into dist/itch/theme/.

    python dist/itch/make_theme_gifs.py [preview_dir]

Everything is drawn on the game's 2 px art grid with the palette from core/Art.hx
and the glyphs from core/PixelFont.hx, so it matches the game without any image
files. All motion uses whole cycles per loop, so the GIFs loop without a seam.
With preview_dir, it also writes a contact sheet of each GIF there.
"""
import math
import random
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "dist" / "itch" / "theme"
FONT_SRC = (ROOT / "source" / "core" / "PixelFont.hx").read_text(encoding="utf-8")

PX = 2  # screen pixels per art pixel, Art.PX in the game
FRAMES = 100
DELAY_MS = 50  # 20 fps, 5 second loop
HERO_FRAME = 30  # ship parked, stamp down
# Portrait file and frame colour for each pilot, in relay order (Art.CAST and Pilots.ALL).
PILOT_CARDS = ((181, 0x5A7AE0), (495, 0x3FD6C2), (207, 0x58D68D), (357, 0x2FA866), (6, 0x3CF0FF))


def rgb(h):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255)


VOID, INK, HULL = rgb(0x120E22), rgb(0x211C2B), rgb(0x2B2440)
KRAFT, KRAFT_DK, TAPE_LINE = rgb(0xD9B98A), rgb(0xB8935A), rgb(0x8A6A3A)
PAPER, WHITE, LILAC, DIM = rgb(0xEEEAE0), rgb(0xF2F2F5), rgb(0xC9C2DE), rgb(0x5A5468)
MID = rgb(0x8A83A6)
ORANGE, AMBER, HAZARD, SUN, PALE = rgb(0xFF5B1F), rgb(0xFF9A3C), rgb(0xFFC21A), rgb(0xFFE45C), rgb(0xFFF4A0)
EMBER, TEAL, BLUE, RED = rgb(0x8A1C28), rgb(0x3FD6C2), rgb(0x5A7AE0), rgb(0xE5343F)
NEB_A, NEB_B, SHADOW = rgb(0x14204A), rgb(0x1A1050), rgb(0x000000)

COLORS = [VOID, INK, HULL, KRAFT, KRAFT_DK, TAPE_LINE, PAPER, WHITE, LILAC, DIM, MID, ORANGE, AMBER,
          HAZARD, SUN, PALE, EMBER, TEAL, BLUE, RED, NEB_A, NEB_B, SHADOW]
PALETTE_IMG = Image.new("P", (1, 1))
PALETTE_IMG.putpalette([v for c in COLORS for v in c] + [0] * (768 - 3 * len(COLORS)))


# ---------------------------------------------------------------- type

GLYPHS = {m[0]: re.findall(r'"([^"]*)"', m[1])
          for m in re.findall(r'"(.)"\s*=>\s*\[([^\]]*)\]', FONT_SRC)}
_space = re.search(r"SPACE:Int\s*=\s*(\d+)", FONT_SRC)
SPACE = int(_space.group(1)) if _space else 3


def text_mask(text, scale):
    """Waybill text as an L mask, with the same bold rule and advance as PixelFont.each."""
    lit = []
    cx = 0
    for ch in text:
        if ch == " ":
            cx += SPACE + 1
            continue
        g = GLYPHS[ch]
        for r, row in enumerate(g):
            for c, v in enumerate(row):
                if v != "#":
                    continue
                lit.append((cx + c, r))
                a = row[c + 1] if c + 1 < len(row) else "."
                b = row[c + 2] if c + 2 < len(row) else "."
                if a != "#" and b != "#":
                    lit.append((cx + c + 1, r))
        cx += len(g[0]) + 2
    w = max(x for x, _ in lit) + 1
    h = max(y for _, y in lit) + 1
    im = Image.new("L", (w, h), 0)
    for p in lit:
        im.putpixel(p, 255)
    return im.resize((w * scale, h * scale), Image.NEAREST)


def put_text(img, text, scale, color, x=None, y=0, cx=None):
    m = text_mask(text, scale)
    if cx is not None:
        x = cx - m.width // 2
    img.paste(color, (x, y), m)
    return m.size


# ---------------------------------------------------------------- sprites

def supersampled(w, h, draw, ss=4):
    im = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
    draw(ImageDraw.Draw(im), ss)
    return im.resize((w, h), Image.NEAREST)


def scaled(pts, k):
    return [(x * k, y * k) for x, y in pts]


SHIP_PTS = [(42, 0), (52, 30), (58, 56), (82, 84), (84, 100), (60, 96), (54, 108), (30, 108),
            (24, 96), (0, 100), (2, 84), (26, 56), (32, 30)]


def make_ship():
    """Art.ship() at art-pixel size: an 84x110 screen sprite, Nova's livery."""
    def draw(d, ss):
        k = ss / 2
        pts = scaled([(x + 2, y + 2) for x, y in SHIP_PTS], k)
        d.polygon(pts, fill=HULL + (255,))
        d.line(pts + pts[:1], fill=WHITE + (255,), width=int(1.5 * ss), joint="curve")
        for wing in ([(26, 58), (2, 86), (2, 92), (30, 66)], [(58, 58), (82, 86), (82, 92), (54, 66)]):
            d.polygon(scaled([(x + 2, y + 2) for x, y in wing], k), fill=BLUE + (255,))
        d.rectangle(scaled([(35, 68), (53, 88)], k), fill=KRAFT + (255,), outline=INK + (255,), width=ss)
        d.line(scaled([(44, 68), (44, 88)], k), fill=TAPE_LINE + (255,), width=ss)
        d.ellipse(scaled([(38, 26), (50, 50)], k), fill=TEAL + (255,))
        d.ellipse(scaled([(40.5, 30), (44, 39)], k), fill=WHITE + (255,))
    return supersampled(44, 57, draw)


def make_flame(power):
    """Art.flame(), stretched by engine power."""
    length = max(6, int(35 * power))
    def draw(d, ss):
        w, h = 15 * ss, length * ss
        d.polygon([(0, 0), (w, 0), (w / 2, h)], fill=ORANGE + (255,))
        d.polygon([(3 * ss, 0), (12 * ss, 0), (w / 2, h * 0.63)], fill=SUN + (255,))
        d.polygon([(5 * ss, 0), (10 * ss, 0), (w / 2, h * 0.31)], fill=WHITE + (255,))
    return supersampled(15, length, draw)


def make_parcel():
    """Art.parcel() at half size, so it stays cargo rather than a second subject."""
    im = Image.new("RGBA", (26, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([3, 6, 22, 20], fill=KRAFT + (255,), outline=INK + (255,))
    d.rectangle([11, 7, 14, 19], fill=KRAFT_DK + (255,))
    d.rectangle([5, 13, 9, 18], fill=PAPER + (255,))
    return im


def make_label(w, h):
    """Art.label(): shipping tag with a chamfer, ink outline, hard shadow and punched hole."""
    im = Image.new("RGBA", (w + 3, h + 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def chamfer(x, y, a, b, c=4):
        return [(x + c, y), (x + a - c, y), (x + a, y + c), (x + a, y + b - c),
                (x + a - c, y + b), (x + c, y + b), (x, y + b - c), (x, y + c)]
    d.polygon(chamfer(3, 4, w - 1, h - 1), fill=SHADOW + (255,))
    d.polygon(chamfer(0, 0, w - 1, h - 1), fill=KRAFT + (255,), outline=INK + (255,))
    cy = (h - 1) // 2
    d.ellipse([6, cy - 3, 12, cy + 3], fill=VOID + (255,), outline=INK + (255,))
    return im


def make_stamp(text, scale, color, angle, seed=7):
    """Distressed rubber stamp with a double frame, baked at a slight tilt."""
    m = text_mask(text, scale)
    pad_x, pad_y = 8, 7
    w, h = m.width + pad_x * 2, m.height + pad_y * 2
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, w - 1, h - 1], 4, outline=255, width=2)
    d.rounded_rectangle([3, 3, w - 4, h - 4], 3, outline=255, width=1)
    mask.paste(255, (pad_x, pad_y), m)

    # Ink misses in patches, so it reads as pressed rather than printed.
    a = np.array(mask)
    rng = np.random.default_rng(seed)
    blotch = np.array(Image.fromarray((rng.random((h // 4 + 2, w // 4 + 2)) * 255).astype("uint8"))
                      .resize((w, h), Image.BILINEAR))
    a[(blotch > 185) & (rng.random(a.shape) < 0.4)] = 0
    mask = Image.fromarray(a).rotate(angle, Image.NEAREST, expand=True)

    im = Image.new("RGBA", mask.size, color + (0,))
    im.putalpha(mask)
    return im


# ---------------------------------------------------------------- backdrop

def value_noise(w, h, cell, rng):
    g = rng.random((h // cell + 3, w // cell + 3))
    ys, xs = np.mgrid[0:h, 0:w]
    x, y = xs / cell, ys / cell
    x0, y0 = x.astype(int), y.astype(int)
    fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    top = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    bot = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return top * (1 - fy) + bot * fy


def make_backdrop(w, h, seed):
    """StarShader's look with the motion taken out: flat nebula contours and fixed stars."""
    rng = np.random.default_rng(seed)
    n = sum(value_noise(w, h, c, rng) * a for c, a in ((70, 0.55), (32, 0.3), (14, 0.15)))
    a = np.empty((h, w, 3), "uint8")
    a[:] = VOID
    a[n > 0.60] = NEB_B
    a[n > 0.67] = NEB_A
    r = rng.random((h, w))
    a[r > 0.994] = MID
    a[r > 0.9985] = WHITE
    return Image.fromarray(a, "RGB")


def twinkles(w, h, count, seed):
    r = random.Random(seed)
    return [(r.randrange(w), r.randrange(h), r.randrange(FRAMES), r.choice((2, 3, 4))) for _ in range(count)]


def draw_twinkles(d, stars, f):
    for x, y, phase, cycles in stars:
        if math.sin(2 * math.pi * (cycles * f + phase) / FRAMES) > 0:
            d.line([(x - 1, y), (x + 1, y)], fill=LILAC)
            d.line([(x, y - 1), (x, y + 1)], fill=LILAC)


def hazard_strip(w, h, f, period=20):
    """Art.hazard(), scrolling one art pixel a frame. FRAMES must be a multiple of period."""
    im = Image.new("RGB", (w, h), HAZARD)
    d = ImageDraw.Draw(im)
    for x in range(-2 * period + f % period, w + period, period):
        d.polygon([(x, h), (x + h, 0), (x + h + period // 2, 0), (x + period // 2, h)], fill=INK)
    return im


def stamp_at(img, stamp, cx, cy, u, slam_u, off_u):
    """Slams a stamp in over three frames. Returns the camera shake for this frame."""
    frame = (u - slam_u) * FRAMES
    if frame < -3 or u >= off_u:
        return 0
    if frame < 0:
        k = 1 + 0.35 * -frame
        s = stamp.resize((int(stamp.width * k), int(stamp.height * k)), Image.NEAREST)
    else:
        s = stamp
    img.paste(s, (int(cx - s.width / 2), int(cy - s.height / 2)), s)
    return {0: 3, 1: -2, 2: 1}.get(int(frame), 0) if frame >= 0 else 0


# ---------------------------------------------------------------- the ship's loop

def hash01(*v):
    return random.Random(hash(v)).random()


def ship_travel(u):
    """Distance along the flight path from parked, in art pixels, and how hard the engine is lit.

    Negative is behind the parked spot, positive is ahead of it. The ship flies in,
    settles, bobs, pulls back, and then punches out. It is off screen at the loop seam.
    """
    if u < 0.04:
        return -700, 2.2
    if u < 0.14:  # arrive, overshooting a little and settling
        t = (u - 0.04) / 0.10
        return -700 * (1 - t) ** 3 + 22 * math.sin(t * math.pi) ** 2, 2.2 - 1.2 * t
    if u < 0.82:  # cruise, phrased to start and end at zero
        t = (u - 0.14) / 0.68
        return 7 * math.sin(2 * math.pi * 4 * t), 1.0
    if u < 0.87:  # anticipation
        t = (u - 0.82) / 0.05
        return -16 * math.sin(t * math.pi / 2), 0.55
    if u < 0.97:  # punch it
        t = (u - 0.87) / 0.10
        return -16 + 860 * t ** 2.4, 2.6
    return 900, 2.6


def ship_sprite(ship, f, travel_speed, power):
    """Ship plus flame, nose up, with the ship anchored at the sprite's centre."""
    flicker = (1.0, 0.8, 1.15, 0.9)[f % 4]
    flame = make_flame(power * flicker)
    stretch = 1 + min(0.45, abs(travel_speed) / 90)
    sw = max(8, int(ship.width / (1 + (stretch - 1) * 0.5)))
    sh = int(ship.height * stretch)
    body = ship.resize((sw, sh), Image.NEAREST)
    half = sh // 2 + flame.height + 4
    im = Image.new("RGBA", (max(sw, flame.width) + 2, half * 2), (0, 0, 0, 0))
    bx = (im.width - sw) // 2
    fx = (im.width - flame.width) // 2
    im.paste(flame, (fx, half + sh // 2 - 7), flame)
    im.paste(body, (bx, half - sh // 2), body)
    return im


def draw_exhaust(d, f, tail_at, drift_at):
    """Sparks left behind the engine. tail_at(frame) is the emitter, drift_at moves a spark away."""
    for age in range(1, 15):
        ef = (f - age) % FRAMES
        x, y = tail_at(ef)
        for k in range(2):
            if hash01(ef, k, 3) * 14 < age:
                continue
            spread = (hash01(ef, k, 1) - 0.5) * 12
            drift = age * (2 + hash01(ef, k, 2) * 3)
            c = PALE if age < 3 else SUN if age < 5 else AMBER if age < 8 else ORANGE if age < 11 else EMBER
            size = 1 if age > 6 else 2
            sx, sy = drift_at(x, y, spread, drift)
            d.rectangle([sx, sy, sx + size - 1, sy + size - 1], fill=c)


def speed_at(f):
    a, _ = ship_travel(f / FRAMES)
    b, _ = ship_travel(((f + 1) % FRAMES) / FRAMES)
    return b - a if abs(b - a) < 400 else 0


def warp_boost(u):
    """Star streaks stretch while the ship is moving hard."""
    if u < 0.14:
        return 1.0 + 1.6 * (1 - u / 0.14)
    if 0.87 <= u:
        return 1.0 + 1.6 * min(1, (u - 0.87) / 0.04)
    return 1.0


def tumbling(parcel, f, turns, phase=0.0):
    angle = 360 * (turns * f / FRAMES + phase)
    return parcel.rotate(angle, Image.NEAREST)


# ---------------------------------------------------------------- scenes

def finish(img, top, shake):
    """Upscales an art-grid frame, adds the title layer, and applies camera shake to the lot."""
    big = img.resize((img.width * PX, img.height * PX), Image.NEAREST)
    if top:
        big.paste(top, (0, 0), top)
    if shake:
        big = Image.fromarray(np.roll(np.array(big), shake * PX, axis=1))
    return big

def title_layer(w, h, cx, logo_y, label_w, label_y, tag_y):
    """Logo, tape and tagline in screen pixels. The game draws this type at 3 and 8 screen px."""
    top = Image.new("RGBA", (w * PX, h * PX), (0, 0, 0, 0))
    cx *= PX
    logo = text_mask("HYPERDASH", 8)
    top.paste(INK + (255,), (cx - logo.width // 2 + 7, logo_y + 7), logo)
    top.paste(ORANGE + (255,), (cx - logo.width // 2, logo_y), logo)
    label = make_label(label_w // PX, 26)
    label = label.resize((label.width * PX, label.height * PX), Image.NEAREST)
    lx = cx - label.width // 2
    top.paste(label, (lx, label_y), label)
    sub = text_mask("LIGHTSPEED COURIER", 3)
    top.paste(INK + (255,), (lx + 12 + (label_w - 12 - sub.width) // 2, label_y + (50 - sub.height) // 2), sub)
    tag = text_mask("2 minutes or it's free.", 3)
    top.paste(INK + (255,), (cx - tag.width // 2 + 3, tag_y + 3), tag)
    top.paste(LILAC + (255,), (cx - tag.width // 2, tag_y), tag)
    return top


def render_embed(clean=False):
    """540x960, the game's own viewport. Warp streaks radiate from the centre, where itch puts
    its Run game button, so nothing solid sits there except the ship passing on its way out.
    With clean, only the backdrop and star streaks are drawn."""
    w, h = 270, 480
    cx, cy = w // 2, h // 2
    back = make_backdrop(w, h, 11)
    stars = twinkles(w, h, 16, 3)
    rng = random.Random(21)
    streaks = []
    for _ in range(110):
        v = rng.random()
        color = WHITE if v < 0.35 else LILAC if v < 0.65 else MID if v < 0.85 else KRAFT if v < 0.94 else TEAL
        streaks.append((rng.uniform(0, math.tau), rng.random(), rng.choice((1, 2, 2, 3)), color))

    top = title_layer(w, h, cx, 68, 440, 144, 216)

    ship = make_ship()
    parcel = make_parcel()
    stamp = make_stamp("EXPRESS", 2, RED, 7)
    park_y = 352

    def tail_pos(frame):
        t, _ = ship_travel(frame / FRAMES)
        return cx, park_y - t + 30

    drift = lambda x, y, spread, away: (int(x + spread), int(y + away))

    frames = []
    for f in range(FRAMES):
        u = f / FRAMES
        img = back.copy()
        d = ImageDraw.Draw(img)
        draw_twinkles(d, stars, f)
        boost = warp_boost(u)
        for a, ph, k, color in streaks:
            p = (ph + k * u) % 1
            if p < 0.12:
                continue
            r = p * p * 330 + 6
            ln = (2 + 26 * p * p) * boost
            ca, sa = math.cos(a), math.sin(a)
            d.line([(cx + ca * max(r - ln, 3), cy + sa * max(r - ln, 3)), (cx + ca * r, cy + sa * r)], fill=color)

        if clean:
            frames.append(finish(img, None, 0))
            continue

        for px0, turns, ph in ((30, 2, 0.1), (240, 3, 0.6)):
            y = -30 + ((ph + 2 * u) % 1) * (h + 60)
            s = tumbling(parcel, f, turns, ph)
            img.paste(s, (px0 - 13, int(y) - 13), s)

        travel, power = ship_travel(u)
        draw_exhaust(d, f, tail_pos, drift)
        sp = ship_sprite(ship, f, speed_at(f), power)
        sx, sy = cx - sp.width // 2, int(park_y - travel) - sp.height // 2
        if -sp.height < sy < h:
            img.paste(sp, (sx, sy), sp)

        shake = stamp_at(img, stamp, 202, 430, u, 0.2, 0.93)
        img.paste(hazard_strip(w, 8, f), (0, h - 8))
        frames.append(finish(img, top, shake))
    return frames


def render_banner(clean=False):
    """960x300, itch's banner slot. It replaces the page title, so it carries the logo.
    With clean, only the backdrop and star streaks are drawn."""
    w, h = 480, 150
    back = make_backdrop(w, h, 29)
    stars = twinkles(w, h, 12, 5)
    rng = random.Random(9)
    streaks = []
    for _ in range(46):
        k = rng.choice((1, 1, 2, 2, 3, 4))
        v = rng.random()
        color = {1: DIM, 2: MID, 3: LILAC, 4: WHITE}[k]
        if k >= 3 and v < 0.25:
            color = KRAFT if v < 0.15 else TEAL
        y = rng.randrange(h) if clean else rng.choice([v for v in range(h - 8) if not 94 <= v <= 114])
        streaks.append((y, rng.random(), k, color, 8 + k * 9))

    top = title_layer(w, h, 196, 36, 440, 116, 196)

    ship = make_ship()
    parcel = make_parcel()
    stamp = make_stamp("EXPRESS", 2, RED, 6)
    park_x, park_y = 396, 58

    def tail_pos(frame):
        t, _ = ship_travel(frame / FRAMES)
        return park_x + t - 30, park_y

    drift = lambda x, y, spread, away: (int(x - away), int(y + spread))

    frames = []
    for f in range(FRAMES):
        u = f / FRAMES
        img = back.copy()
        d = ImageDraw.Draw(img)
        draw_twinkles(d, stars, f)
        boost = warp_boost(u)
        for y, ph, k, color, ln in streaks:
            span = w + 180
            x = w + 90 - ((ph + k * 2 * u) % 1) * span
            d.line([(x, y), (x + ln * boost, y)], fill=color)

        if clean:
            frames.append(finish(img, None, 0))
            continue

        s = tumbling(parcel, f, 2, 0.3)
        px = w + 30 - ((0.7 + 2 * u) % 1) * (w + 60)
        img.paste(s, (int(px) - 13, 117), s)

        travel, power = ship_travel(u)
        draw_exhaust(d, f, tail_pos, drift)
        sp = ship_sprite(ship, f, speed_at(f), power).transpose(Image.ROTATE_270)
        sx, sy = int(park_x + travel) - sp.width // 2, int(park_y + math.sin(u * math.tau * 3) * 2) - sp.height // 2
        if -sp.width < sx < w:
            img.paste(sp, (sx, sy), sp)

        shake = stamp_at(img, stamp, 396, 111, u, 0.2, 0.93)
        img.paste(hazard_strip(w, 8, f), (0, h - 8))
        frames.append(finish(img, top, shake))
    return frames


def render_background():
    """512x512 tile for itch's page Background slot: the static tile with quiet motion added.

    Streaks fall as if the page were flying nose up like the ship. Every pixel wraps at the
    tile edge, so the tile repeats without a seam in space as well as in time.
    """
    size = 256
    base = Image.open(OUT / "background_tile_512.png").convert("RGB")
    base = base.resize((size, size), Image.NEAREST)
    rng = random.Random(14)
    streaks = []
    for x in rng.sample(range(0, size, 6), 16):
        k = rng.choice((1, 1, 2, 2, 3))
        color = {1: DIM, 2: MID, 3: LILAC}[k]
        if rng.random() < 0.2:
            color = TAPE_LINE
        streaks.append((x, rng.random(), k, color, 6 + k * 8))
    stars = twinkles(size, size, 6, 8)

    frames = []
    for f in range(FRAMES):
        img = base.copy()
        px = img.load()
        for x, y, phase, cycles in stars:
            if math.sin(2 * math.pi * (cycles * f + phase) / FRAMES) > 0:
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1), (0, 0)):
                    px[(x + dx) % size, (y + dy) % size] = LILAC
        for x, ph, k, color, ln in streaks:
            head = int((ph + k * f / FRAMES) * size)
            for i in range(ln):
                px[x, (head - i) % size] = color
        frames.append(finish(img, None, 0))
    return frames


def render_simple_banner():
    """Still 960x300 banner, the cover image cut down: logo, the five pilots, and the promise."""
    w, h = 960, 300
    tile = Image.open(OUT / "background_tile_512.png").convert("RGB")
    img = Image.new("RGB", (w, h))
    img.paste(tile, (0, 0))
    img.paste(tile, (512, 0))
    d = ImageDraw.Draw(img)
    rng = random.Random(6)
    for _ in range(14):
        x, y = rng.randrange(0, w, PX), rng.randrange(0, h, PX)
        d.rectangle([x, y, x + rng.randrange(20, 70, PX), y + 1], fill=rng.choice((WHITE, LILAC, TEAL)))

    logo = text_mask("HYPERDASH", 8)
    lx = (w - logo.width) // 2
    img.paste(INK, (lx + 8, 28), logo)
    img.paste(ORANGE, (lx, 20), logo)

    frame_px, size, gap = 4, 128, 6
    cell = size + frame_px * 2
    x = (w - (cell * len(PILOT_CARDS) + gap * (len(PILOT_CARDS) - 1))) // 2
    for portrait, tint in PILOT_CARDS:
        d.rectangle([x, 90, x + cell - 1, 90 + cell - 1], fill=rgb(tint))
        face = Image.open(ROOT / "assets" / "portraits" / f"{portrait}.png").convert("RGBA")
        face = face.resize((size, size), Image.NEAREST)
        slot = Image.new("RGB", (size, size), SHADOW)
        slot.paste(face, (0, 0), face)
        img.paste(slot, (x + frame_px, 90 + frame_px))
        x += cell + gap

    tag = text_mask("2 MINUTES OR IT'S FREE", 4)
    tx = (w - tag.width) // 2
    img.paste(INK, (tx + 4, 246 + 4), tag)
    img.paste(ORANGE, (tx, 246), tag)
    return img


def render_simple_cover():
    """630x500 cover image: logo, ship and promise, big enough to read at the 315x250 thumbnail."""
    w, h = 315, 250
    cx, cy = w // 2 + 1, 112
    back = make_backdrop(w, h, 17)
    stars = twinkles(w, h, 8, 12)
    rng = random.Random(33)
    streaks = []
    for _ in range(60):
        v = rng.random()
        color = WHITE if v < 0.4 else LILAC if v < 0.7 else MID if v < 0.88 else KRAFT if v < 0.95 else TEAL
        streaks.append((rng.uniform(0, math.tau), rng.random(), rng.choice((1, 2, 2, 3)), color))

    top = Image.new("RGBA", (w * PX, h * PX), (0, 0, 0, 0))
    logo = text_mask("HYPERDASH", 8)
    lx = (w * PX - logo.width) // 2
    top.paste(INK + (255,), (lx + 7, 33), logo)
    top.paste(ORANGE + (255,), (lx, 26), logo)
    tag = text_mask("2 MINUTES OR IT'S FREE", 4)
    tx = (w * PX - tag.width) // 2
    top.paste(INK + (255,), (tx + 4, 438), tag)
    top.paste(ORANGE + (255,), (tx, 434), tag)

    ship = make_ship()
    ship = ship.resize((ship.width * 2, ship.height * 2), Image.NEAREST)

    frames = []
    for f in range(FRAMES):
        u = f / FRAMES
        img = back.copy()
        d = ImageDraw.Draw(img)
        draw_twinkles(d, stars, f)
        for a, ph, k, color in streaks:
            p = (ph + k * u) % 1
            if p < 0.12:
                continue
            r = p * p * 240 + 30
            ln = 2 + 22 * p * p
            ca, sa = math.cos(a), math.sin(a)
            d.line([(cx + ca * (r - ln), cy + sa * (r - ln)), (cx + ca * r, cy + sa * r)], fill=color)

        bob = round(math.sin(u * math.tau * 3) * 3)
        flame = make_flame(1.4 * (1.0, 0.82, 1.12, 0.9)[f % 4])
        flame = flame.resize((flame.width * 2, flame.height), Image.NEAREST)
        sy = cy - ship.height // 2 + bob
        fy = sy + ship.height - 12
        img.paste(flame, (cx - flame.width // 2, fy), flame)
        img.paste(ship, (cx - ship.width // 2, sy), ship)
        img.paste(hazard_strip(w, 8, f), (0, h - 8))
        frames.append(finish(img, top, 0))
    return frames


# ---------------------------------------------------------------- output

def save_gif(frames, path):
    indexed = [fr.quantize(palette=PALETTE_IMG, dither=Image.Dither.NONE) for fr in frames]
    indexed[0].save(path, save_all=True, append_images=indexed[1:], duration=DELAY_MS, loop=0, disposal=1, optimize=False)
    # Same frames as APNG: itch has been flattening some GIF banners, and users report APNG animating there.
    indexed[0].save(path.with_suffix(".apng.png"), save_all=True, append_images=indexed[1:], duration=DELAY_MS, loop=0,
                    disposal=0, blend=0, optimize=True)


def contact_sheet(frames, path, picks=(0, 8, 12, 20, 24, 60, 85, 90), columns=4):
    w, h = frames[0].size
    sheet = Image.new("RGB", (columns * (w + 4), math.ceil(len(picks) / columns) * (h + 4)), (70, 70, 70))
    for i, f in enumerate(picks):
        sheet.paste(frames[f].convert("RGB"), ((i % columns) * (w + 4), (i // columns) * (h + 4)))
    sheet.save(path)


def main():
    preview = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    render_simple_banner().save(OUT / "banner_simple_960x300.png", optimize=True)
    cover = render_simple_cover()
    cover[0].quantize(palette=PALETTE_IMG, dither=Image.Dither.NONE).save(OUT.parent / "cover_simple_630x500.png", optimize=True)
    save_gif(cover, OUT.parent / "cover_simple_630x500.gif")
    for name, render in (("embed_bg_540x960.gif", render_embed), ("banner_960x300.gif", render_banner),
                         ("background_tile_512.gif", render_background),
                         ("embed_bg_clean_540x960.gif", lambda: render_embed(True)),
                         ("banner_clean_960x300.gif", lambda: render_banner(True))):
        frames = render()
        # Start on the hero pose: anything that flattens the GIF keeps only the first frame.
        frames = frames[HERO_FRAME:] + frames[:HERO_FRAME]
        save_gif(frames, OUT / name)
        size = (OUT / name).stat().st_size
        print(f"{name}: {frames[0].width}x{frames[0].height}, {len(frames)} frames, {size / 1024 / 1024:.2f} MB")
        apng = (OUT / name).with_suffix(".apng.png").stat().st_size
        print(f"  APNG copy: {apng / 1024 / 1024:.2f} MB")
        if preview:
            columns = 8 if "embed" in name else 2
            contact_sheet(frames, preview / (name + ".png"), columns=columns)


if __name__ == "__main__":
    main()

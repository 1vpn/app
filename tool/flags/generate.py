#!/usr/bin/env python3
"""Generates square flags in the shipped pack's style.

Usage: python3 tool/flags/generate.py <flag-icons>/flags/1x1 <pack>/svg <map.csv> [code ...]
       python3 tool/flags/generate.py --from-rect <pack>/svg <map.csv> <out-dir> [code ...]

The default mode recolours flag-icons 1x1 SVGs to the vendor palette into assets/onevpn/flags/.
With no codes it writes the shipped FROM_ICONS set. Deferred codes are not in the tree:
name one to write it.
--from-rect centre-crops the vendor rectangles to 1:1, keeping their colours and emblem
sizes. map.csv maps `slug` (file name less its number) to `code`. Reruns are byte-identical.
"""

import colorsys
import csv
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/onevpn/flags'

# The paid pack's originals. The generator never overwrites them.
PACK = set('au br ca cl de es fr il in jp kr mx nl pl ro se sg uk us za'.split())
# Source codes the pack files under another name. gb is the shipped uk.
SKIP = {'gb'}
# The generated codes that ship beside the pack, by source.
FROM_ICONS = set('ae ge id ie is it ke kz my ng nz pa ph th tr tw ua'.split())
FROM_RECT = set('ar ch fi hk lu pt ru'.split())
# The vendor palette, from the pack squares and rectangles. The hue rule maps into it.
WHITE, BLACK, RED, MAROON, BLUE, MIDBLUE = '#F5F5F5', '#464655', '#FF4B55', '#732D37', '#41479B', '#4173CD'
LIGHTBLUE, YELLOW, GOLD, ORANGE, TAN = '#82AFFF', '#FFE15A', '#FAB446', '#FF9B46', '#FFB478'
GREEN, LIGHTGREEN, TEAL, BROWN, DARKBROWN, PINK = '#73AF00', '#AAD264', '#00C3A0', '#9B4B5A', '#783C46', '#FFA0D2'
GREY, PURPLE = '#B4B4BE', '#8C50AA'  # neither source shows these: derived
# Per-code source colour to vendor colour. The palette rule covers every shipped code.
COLOURS = {}
# Per-code geometry edits, literal replacements on the flag-icons source.
GEOMETRY = {
    # The square rendering: the canton fills the top-left quadrant and the sun
    # (192 across at 192,128) scales 0.8 to 60 percent of the canton height.
    'tw': [('d="M0 0h384v256H0z"', 'd="M0 0h256v256H0z"'),
           ('<g fill="#fff">', '<g transform="matrix(.8 0 0 .8 -25.6 25.6)"><g fill="#fff">'),
           ('fill="#fff"/>\n  </g>', 'fill="#fff"/></g>\n  </g>')],
    # The pack's Nordic cross (se): bars 52.96 and 48 wide.
    'fi': [('M0 186.2h512v139.6H0z', 'M0 232h512v48H0z'),
           ('M123.2 0h139.6v512H123.1z', 'M158.9 0h52.96v512H158.9z')],
}
# Hue rule thresholds: hue in degrees, lightness and saturation 0..1 (HLS).
# NEUTRAL_CHROMA catches tints whose HLS saturation inflates near white.
NEUTRAL_SAT, NEUTRAL_CHROMA = 0.18, 0.08  # below either, white, grey or black
WHITE_L, BLACK_L = 0.80, 0.22  # neutral lightness cut-offs
DARK_L, LIGHT_L = 0.25, 0.62  # a hued colour beyond these takes the family's dark or light tint
MIDBLUE_HUE = (196, 210)  # se's blue sits here. Navy starts above it.
# Beyond this distance from every vendor colour of its code, a colour takes the hue rule.
PALETTE_REACH = 45

NAMED = {'red': '#ff0000', 'gold': '#ffd700', 'gray': '#808080', 'grey': '#808080', 'green': '#008000',
         'olive': '#808000', 'maroon': '#800000', 'purple': '#800080', 'white': '#ffffff', 'black': '#000000',
         'blue': '#0000ff', 'yellow': '#ffff00', 'navy': '#000080', 'orange': '#ffa500', 'silver': '#c0c0c0'}

def rgb(value):
    """Parses a hex or named SVG colour. Returns None for none, url() and the like."""
    m = re.fullmatch(r'#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})', NAMED.get(value.strip().lower(), value.strip()))
    h = m and (m[1] if len(m[1]) == 6 else ''.join(c * 2 for c in m[1]))
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)) if h else None

def neutral(c):
    """The neutral pack colour for rgb [c], or None when [c] has a hue."""
    h, l, s = colorsys.rgb_to_hls(*c)
    if s < NEUTRAL_SAT or max(c) - min(c) < NEUTRAL_CHROMA or l > 0.97 or l < 0.10:
        return WHITE if l >= WHITE_L else BLACK if l <= BLACK_L else GREY
    return None

def distance(a, b):
    """Hue-led distance between two hued rgb triples: hue degrees plus lightness."""
    (ha, la, _), (hb, lb, _) = colorsys.rgb_to_hls(*a), colorsys.rgb_to_hls(*b)
    dh = abs(ha - hb) * 360
    return min(dh, 360 - dh) + 100 * abs(la - lb)

def quantise(value, palette=()):
    """Maps an SVG colour to a vendor colour. Non-colours pass through. A neutral
    takes the neutral rule, else the nearest of [palette] (the hued colours of the
    code's vendor rectangle) within PALETTE_REACH, else the hue rule's family colour."""
    c = rgb(value)
    if c is None:
        return value
    if (n := neutral(c)) is not None:
        return n
    near = min(palette, key=lambda p: distance(c, rgb(p)), default=None)
    if near and distance(c, rgb(near)) <= PALETTE_REACH:
        return near
    h, l, s = colorsys.rgb_to_hls(*c)
    h *= 360
    if h < 12 or h >= 345:
        return MAROON if l < DARK_L else PINK if l > 0.80 else RED
    if h < 38:  # orange and brown
        if l < DARK_L:
            return DARKBROWN
        if l < 0.40 or s < 0.45:
            return BROWN
        return TAN if l > 0.72 else GOLD if l > 0.55 else ORANGE
    if h < 70:  # yellow and gold
        if l < 0.30 or s < 0.40:
            return BROWN if l < 0.30 else GOLD
        return YELLOW if l >= 0.42 else GOLD
    if h < 170:
        return LIGHTGREEN if l > LIGHT_L else GREEN
    if h < MIDBLUE_HUE[0]:
        return TEAL if l < DARK_L else LIGHTBLUE
    if h < 265:  # blues. Only blue hues take the light blue.
        return LIGHTBLUE if l > LIGHT_L else MIDBLUE if h < MIDBLUE_HUE[1] else BLUE
    if h < 315:
        return PURPLE
    return PINK if l > 0.70 else RED

ATTR = re.compile(r'\b(fill|stroke|stop-color|flood-color)="([^"]*)"')
STYLE = re.compile(r'\b(fill|stroke|stop-color)\s*:\s*([^;"]+)')

def restyle(svg, code='', palette=()):
    """Returns the source SVG for [code] in the vendor palette on a 512 canvas."""
    if 'viewBox="0 0 512 512"' not in svg:
        raise ValueError('expected a 512 x 512 viewBox')
    for old, new in GEOMETRY.get(code, []):
        if old not in svg:
            raise ValueError(f'{code}: geometry edit no longer matches the source')
        svg = svg.replace(old, new)
    fixed = COLOURS.get(code, {})
    q = lambda v: fixed.get(v.strip().lower()) or quantise(v, palette)
    svg = ATTR.sub(lambda m: f'{m[1]}="{q(m[2])}"', svg)
    svg = re.sub(r'style="([^"]*)"', lambda m: 'style="%s"' % STYLE.sub(
        lambda n: f'{n[1]}:{q(n[2])}', m[1]), svg)
    # The root fill makes unpainted shapes the pack black. A source root fill
    # is kept, recoloured above. The root id names the source set and is dropped.
    def root(m):
        attrs = re.sub(r'\s+id="[^"]*"', '', m[1])
        return '<svg%s>' % (attrs if ' fill=' in attrs else f'{attrs} fill="{BLACK}"')
    return gate_safe(re.sub(r'<svg\b([^>]*)>', root, svg, count=1))

def gate_safe(svg):
    """Returns [svg] free of literals the endpoint gate reads as endpoints."""
    # Plain href (SVG 2) drops the xlink namespace URL. A space splits compact
    # numbers such as 2.1.2.8, which read as IPv4. Neither changes the drawing.
    svg = re.sub(r'\s+xmlns:xlink="[^"]*"', '', svg).replace('xlink:href=', 'href=')
    return re.sub(r'(\d*\.\d+)(?=\.)', r'\1 ', svg).strip() + '\n'

def rectangles(src, map_csv):
    """Maps each code to the text of its vendor rectangle SVG in [src]."""
    with open(map_csv, newline='') as f:
        codes = {r['slug']: r['code'] for r in csv.DictReader(f) if r['code']}
    return {codes[p.stem.split('-', 1)[1]]: p.read_text(encoding='iso-8859-1')
            for p in sorted(src.glob('*.svg')) if p.stem.split('-', 1)[1] in codes}

def palette(rect):
    """The hued colours of a vendor rectangle, sorted for determinism."""
    found = {v.upper() for v in re.findall(r'fill[:=]"?(#[0-9a-fA-F]{6})', rect)}
    return sorted(v for v in found if neutral(rgb(v)) is None)

# The vendor rectangle: a 512-wide field from y 88.275 to 423.725, with
# rounded corners at the x ends only. Its centred square drops the corners.
RECT_TOP, RECT_SIDE = 88.275, 335.45

def from_rect(svg):
    """Returns the vendor rectangle [svg] centre-cropped to a 512 square."""
    svg = re.sub(r'<\?xml[^>]*\?>|<!--.*?-->|<g>\s*</g>', '', svg, flags=re.S)
    box = f'{RECT_TOP} {RECT_TOP} {RECT_SIDE} {RECT_SIDE}'
    svg = re.sub(r'<svg\b[^>]*>', '<svg xmlns="http://www.w3.org/2000/svg" '
                 f'viewBox="{box}" width="512" height="512">', svg, count=1)
    return gate_safe(re.sub(r'\n\s*\n', '\n', svg))

def main(argv):
    if len(argv) < 4 or (argv[1] == '--from-rect' and len(argv) < 5):
        sys.exit('\n'.join(__doc__.strip().splitlines()[2:4]))
    if argv[1] == '--from-rect':
        rects, out = rectangles(pathlib.Path(argv[2]), argv[3]), pathlib.Path(argv[4])
        codes = argv[5:] or sorted(rects)
        for code in codes:
            (out / f'{code}.svg').write_text(from_rect(rects[code]), encoding='utf-8')
        return print(f'wrote {len(codes)} flags to {out}')
    src, rects = pathlib.Path(argv[1]), rectangles(pathlib.Path(argv[2]), argv[3])
    codes = argv[4:] or sorted(FROM_ICONS)
    for code in codes:
        if code in PACK | SKIP:
            sys.exit(f'{code}: a pack original, not generated')
        source = (src / f'{code}.svg').read_text(encoding='utf-8')
        svg = restyle(source, code, palette(rects.get(code, '')))
        (OUT / f'{code}.svg').write_text(svg, encoding='utf-8')
    print(f'wrote {len(codes)} flags to {OUT.relative_to(ROOT)}')

if __name__ == '__main__':
    main(sys.argv)

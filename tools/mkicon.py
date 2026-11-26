#!/usr/bin/env python3
"""生成 1024x1024 应用图标：琥珀底 + 白色 ¥"""
import struct, zlib, math

SIZE = 1024
SS = 3                      # 超采样倍数
S = SIZE * SS

BG = (240, 158, 46)         # 琥珀
FG = (255, 255, 255)

mask = bytearray(S * S)     # 1 = 白色前景


def quad(p0, p1, w):
    """两点 + 线宽 → 平行四边形四个顶点"""
    x0, y0 = p0
    x1, y1 = p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    return [(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)]


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def fill(poly):
    pts = [(x * SS, y * SS) for x, y in poly]
    ys = [p[1] for p in pts]
    y0, y1 = max(0, int(math.floor(min(ys)))), min(S - 1, int(math.ceil(max(ys))))
    n = len(pts)
    for y in range(y0, y1 + 1):
        yc = y + 0.5
        xs = []
        for i in range(n):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % n]
            if (ay <= yc < by) or (by <= yc < ay):
                t = (yc - ay) / (by - ay)
                xs.append(ax + t * (bx - ax))
        xs.sort()
        row = y * S
        for i in range(0, len(xs) - 1, 2):
            xa = max(0, int(round(xs[i])))
            xb = min(S - 1, int(round(xs[i + 1])))
            for x in range(xa, xb + 1):
                mask[row + x] = 1


W = 62
DY = 46
def Y(v): return v + DY

fill(quad((336, Y(236)), (512, Y(468)), W))          # 左撇
fill(quad((688, Y(236)), (512, Y(468)), W))          # 右撇
fill(rect(512 - W // 2, Y(452), 512 + W // 2, Y(742)))   # 竖
fill(rect(512 - 158, Y(556), 512 + 158, Y(556 + 54)))    # 上横
fill(rect(512 - 158, Y(648), 512 + 158, Y(648 + 54)))    # 下横

rows = []
for y in range(SIZE):
    line = bytearray()
    line.append(0)  # filter type 0
    base = y * SS * S
    for x in range(SIZE):
        acc = 0
        idx = base + x * SS
        for dy in range(SS):
            rowbase = idx + dy * S
            acc += mask[rowbase] + mask[rowbase + 1] + mask[rowbase + 2]
        a = acc / (SS * SS)
        r = int(BG[0] + (FG[0] - BG[0]) * a)
        g = int(BG[1] + (FG[1] - BG[1]) * a)
        b = int(BG[2] + (FG[2] - BG[2]) * a)
        line += bytes((r, g, b))
    rows.append(bytes(line))

raw = b"".join(rows)


def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw, 9))
png += chunk(b"IEND", b"")

out = "/tmp/piggy/PiggyPot/Assets.xcassets/AppIcon.appiconset/icon1024.png"
open(out, "wb").write(png)
print(out, len(png), "bytes")

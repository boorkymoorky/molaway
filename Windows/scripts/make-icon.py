#!/usr/bin/env python3
"""Original Molaway two-ring vector geometry rasterized into a Windows icon.
No third-party assets or image libraries. Reproducible output without metadata.
"""
from pathlib import Path
import math, struct, zlib
size = 256
pixels = bytearray()
for y in range(size):
    pixels.append(0)
    for x in range(size):
        dx, dy = x + .5 - 128, y + .5 - 128
        radius = math.hypot(dx, dy)
        angle = math.degrees(math.atan2(dy, dx))
        edge = min(1, max(0, (122 - max(abs(dx), abs(dy))) / 2))
        color = [24, 35, 43]
        for r, target in [(86, (109, 218, 187)), (58, (145, 167, 243))]:
            coverage = max(0, min(1, 5.5 - abs(radius - r)))
            if 55 < angle < 125: coverage = 0
            color = [round(v * (1-coverage) + t*coverage) for v,t in zip(color,target)]
        pixels.extend([*color, round(255 * edge)])
def chunk(kind, data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
png = b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(pixels,9))+chunk(b'IEND',b'')
root = Path(__file__).resolve().parents[1] / 'Molaway.Windows/Assets'
root.mkdir(exist_ok=True)
(root/'Molaway.ico').write_bytes(struct.pack('<3H',0,1,1)+struct.pack('<4B2H2I',0,0,0,0,1,32,len(png),22)+png)

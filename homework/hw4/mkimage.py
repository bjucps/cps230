#!/usr/bin/env python3
"""mkimage.py: Python script to generate final linked image file for HW4

As posted, this script generates the final image.bin file for the "Mr. Nobody"
HW4 handout sheet discussed and worked out in class.

You may repurpose it to generate your own HW4 image.bin file via these steps:

* replace all the data in `RAW` with the hexdump bytes of your own HW4's
    .text and .data sections (in the right order, with appropriate padding)

* replace the value of `BASE_ADDR` with the right address from your HW4 sheet

* replace all the `patch(image, ...)` calls with appropriate calls for your
    HW4's final table of relocations

If all these steps are followed correctly (and your HW4 work sheet was also
completed correctly), the resulting modified script will produce an image.bin
file whose MD5 checksum matches that predicted by your HW4 instructions.
"""
import hashlib

RAW = bytes.fromhex("""\
CC CC CC A1 04 00 00 00 33 05 00 00 00 00 C3 CC
A1 00 00 00 00 03 05 00 00 00 00 C3 00 00 00 00

CC CC 55 89 E5 FF 35 02 00 00 00 E8 00 00 00 00
83 C4 04 5D C3 00 00 00 00 00 00 00 00 00 00 00

26 02 00 00 00 00 00 00 00 00 00 00 00 00 00 00

00 00 BC 02 00 00 00 00 F4 01 00 00 
""")

BASE_ADDR = 0x4a79c00

def patch(image: bytearray, addr: int, value: int, size: int = 4, endian: str = "little"):
    offset = addr - BASE_ADDR
    image[offset:offset+size] = value.to_bytes(size, endian)

image = bytearray(RAW)
patch(image, 0x4a79c04, 0x4a79c44)
patch(image, 0x4a79c0a, 0x4a79c58)
patch(image, 0x4a79c11, 0x4a79c58)
patch(image, 0x4a79c17, 0x4a79c40)
patch(image, 0x4a79c27, 0x4a79c52)
patch(image, 0x4a79c2c, 0xffffffd3)
patch(image, 0x4a79c44, 0x4a79c22)

print(f"image.bin: {len(image)} bytes long, MD5 {hashlib.md5(image).hexdigest()}")
with open("image.bin", "wb") as fd:
    fd.write(image)


#!/usr/bin/env python3
"""
simg2img.py — Android sparse image -> raw ext4 converter (project-owned tool)

Implements enough of the Android sparse image format (header v1.0) to convert
Samsung / AOSP sparse ext4 images into raw filesystem images readable by
debugfs/7z/losetup without root.

Format reference: AOSP system/core/libsparse/sparse_format.h
  magic 0xED26FF2A, major 1, minor 0, file_hdr_sz, chunk_hdr_sz,
  blk_sz, output size = total_blks * blk_sz
chunk types:
  RawData   0xCAC1 : (chunk_size input u32 already consumed) raw bytes blk*blk_sz
  Fill      0xCAC2 : 4-byte u32 pattern, expanded over nl_blocks
  DontCare  0xCAC3 : nl_blocks of zeros
  CRC32     0xCAC4 : 4-byte u32 checksum (skip pt, advance output? no output)
"""
import sys, struct, os

SPARSE_MAGIC = 0xED26FF3A
CHUNK_RAW, CHUNK_FILL, CHUNK_DONT_CARE, CHUNK_CRC = 0xCAC1, 0xCAC2, 0xCAC3, 0xCAC4

def main(inpath, outpath):
    with open(inpath, 'rb') as f:
        (magic, major, minor, file_hdr, chunk_hdr,
         blk_sz, total_blks, in_chunks, crc) = struct.unpack('<IHHHHIIII', f.read(28))
        if magic != SPARSE_MAGIC:
            sys.exit(f"not an android sparse image: {inpath}")
        if major != 1:
            sys.exit(f"unsupported sparse major version {major}")
        total_out = total_blks * blk_sz
        print(f"magic ok v{major}.{minor}; file_hdr={file_hdr} chunk_hdr={chunk_hdr}; "
              f"blk_sz={blk_sz} ({blk_sz>>10} KiB), total_blks={total_blks} -> "
              f"output {total_out/1024/1024:.1f} MiB, chunks={in_chunks}")
        f.seek(file_hdr)
        written = 0
        with open(outpath, 'wb') as out:
            for i in range(in_chunks):
                hdr = f.read(chunk_hdr)
                ct, resv, nl_blocks, tsize = struct.unpack('<HHII', hdr[:12])
                payload_len = tsize - chunk_hdr
                nbytes = nl_blocks * blk_sz
                if ct == CHUNK_RAW:
                    raw = f.read(payload_len)
                    out.write(raw)
                    if nbytes > payload_len:
                        out.write(b'\0' * (nbytes - payload_len))
                elif ct == CHUNK_FILL:
                    pat = struct.unpack('<I', f.read(4))[0]
                    word = struct.pack('<I', pat)
                    out.write(word * (nbytes // 4) + b'\0' * (nbytes % 4))
                elif ct == CHUNK_DONT_CARE:
                    out.write(b'\0' * nbytes)
                elif ct == CHUNK_CRC:
                    f.read(4)
                    written -= 0  # CRC adds no output
                    continue
                else:
                    sys.exit(f"unknown chunk type 0x{ct:04X} at chunk {i} (offset {file_hdr + i})")
                written += nbytes
        if written != total_out:
            print(f"NOTE: output {written} != declared {total_out} bytes")
        else:
            print(f"done: wrote {written/1024/1024:.1f} MiB to {outpath}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <input.sparse> <output.raw>")
    main(sys.argv[1], sys.argv[2])

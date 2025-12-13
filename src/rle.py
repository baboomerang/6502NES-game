import argparse
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Config:
    command: str
    file: Path


def rle_compress(path: Path):
    """Compress file using 1-byte-count RLE (C++ compatible)."""
    out_path = path.with_suffix(path.suffix + ".rle")

    with path.open("rb") as inp, out_path.open("wb") as out:
        prev = inp.read(1)
        if not prev:
            return

        count = 1

        while True:
            curr = inp.read(1)
            if curr == prev and curr:
                count += 1
                if count == 256:  # max 1-byte count
                    out.write(bytes([255]) + prev)
                    count = 1
            else:
                out.write(bytes([count]) + prev)
                if not curr:
                    break
                prev = curr
                count = 1

    print(f"Compressed to: {out_path}")


def rle_decompress(path: Path):
    """Decompress a file produced by rle_compress()."""
    out_path = path.with_suffix(path.suffix + ".raw")

    with path.open("rb") as inp, out_path.open("wb") as out:
        while True:
            count_b = inp.read(1)
            if not count_b:
                break
            byte_b = inp.read(1)
            if not byte_b:
                raise ValueError("Corrupted RLE input: missing byte value")

            out.write(byte_b * count_b[0])

    print(f"Decompressed to: {out_path}")


def build_parser():
    parser = argparse.ArgumentParser(
        description="Simple Run-Length Encoding (RLE) compressor/decompressor."
    )
    sub = parser.add_subparsers(dest="command", required=True)
    p_comp = sub.add_parser("compress", help="Compress a file.")
    p_comp.add_argument("file", type=Path)
    p_decomp = sub.add_parser("decompress", help="Decompress an RLE-compressed file.")
    p_decomp.add_argument("file", type=Path)
    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    config = Config(command=args.command, file=args.file)

    if not config.file.exists():
        parser.error(f"File not found: {config.file}")

    if config.command == "compress":
        rle_compress(config.file)
    else:
        rle_decompress(config.file)


if __name__ == "__main__":
    main()

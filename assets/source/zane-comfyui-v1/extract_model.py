"""Reconstruct the exact user-supplied Zane GLB; Python standard library only."""
from pathlib import Path
import hashlib
import lzma

ROOT = Path(__file__).resolve().parent
EXPECTED = "ef64a48342e6909a5a407bdd78ea98b1f5644fbf561881b09966aa554880b4f5"

def main():
    parts = [ROOT / f"zane-comfyui-v1.glb.xz.part{i:03d}" for i in range(1, 16)]
    data = lzma.decompress(b"".join(p.read_bytes() for p in parts))
    if len(data) != 59764984 or hashlib.sha256(data).hexdigest() != EXPECTED:
        raise ValueError("Reconstructed model does not match the original checksum")
    output = ROOT / "zane-comfyui-v1.glb"
    with output.open("xb") as handle:
        handle.write(data)
    print(f"Verified original model: {output}")

if __name__ == "__main__":
    main()

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_FILES = [
    ROOT / "src" / "assets" / "assetRegistry.js",
    ROOT / "godot" / "scripts" / "data" / "AssetRegistry.gd",
    ROOT / "src" / "game" / "data" / "units.js",
    ROOT / "src" / "game" / "data" / "enemies.js",
]
ASSET_PATH = re.compile(r"""["']((?:/src|res://)[^"']+?\.(?:png|svg))["']""")


def local_path(asset_path: str) -> Path:
    if asset_path.startswith("/src/"):
        return ROOT / asset_path.removeprefix("/")
    return ROOT / "godot" / asset_path.removeprefix("res://")


def main() -> None:
    missing: list[str] = []
    for source in SOURCE_FILES:
        text = source.read_text(encoding="utf-8")
        for asset_path in ASSET_PATH.findall(text):
            if not local_path(asset_path).exists():
                missing.append(f"{source.relative_to(ROOT).as_posix()}: {asset_path}")

    if missing:
        print("Missing referenced assets:")
        print("\n".join(missing))
        raise SystemExit(1)

    print("All referenced asset paths exist.")


if __name__ == "__main__":
    main()

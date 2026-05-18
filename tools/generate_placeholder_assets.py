from __future__ import annotations

from pathlib import Path
from math import cos, sin, pi

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src" / "assets"
GODOT = ROOT / "godot" / "assets"
GAME_PLACEHOLDERS = ROOT / "src" / "game" / "assets" / "placeholders"


def ensure(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save(img: Image.Image, path: Path) -> None:
    ensure(path)
    img.save(path)
    print(path.relative_to(ROOT).as_posix())


def diamond(draw: ImageDraw.ImageDraw, cx: int, cy: int, w: int, h: int, fill, outline, width: int = 2) -> None:
    pts = [(cx, cy - h // 2), (cx + w // 2, cy), (cx, cy + h // 2), (cx - w // 2, cy)]
    draw.polygon(pts, fill=fill)
    draw.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def panel(path: Path, size: tuple[int, int], base: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=8, fill=(*base, 232), outline=(*accent, 255), width=3)
    d.rectangle((6, 6, size[0] - 7, 12), fill=(*accent, 90))
    for x in range(10, size[0] - 10, 18):
        d.line((x, size[1] - 9, x + 8, size[1] - 9), fill=(255, 236, 188, 65), width=1)
    save(img, path)


def bar_frame(path: Path, color: tuple[int, int, int]) -> None:
    img = Image.new("RGBA", (144, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 143, 23), radius=6, fill=(23, 24, 28, 235), outline=(202, 176, 119, 255), width=2)
    d.rounded_rectangle((6, 6, 108, 17), radius=4, fill=(*color, 205))
    d.rectangle((112, 7, 136, 16), fill=(255, 245, 210, 46))
    save(img, path)


def tile(path: Path, base: tuple[int, int, int], accent: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    diamond(d, 48, 32, 88, 54, (*base, 255), (*accent, 255), 3)
    for y in range(18, 50, 8):
        d.line((16, y, 48, y + 18, 80, y), fill=(*accent, 54), width=1)
    if kind == "water":
        for y in (27, 34, 41):
            d.arc((24, y - 7, 72, y + 7), 0, 180, fill=(156, 230, 255, 160), width=2)
    elif kind == "road":
        d.line((18, 35, 48, 20, 78, 35), fill=(222, 205, 158, 185), width=7)
    elif kind == "wall":
        for x in range(24, 73, 16):
            d.rectangle((x, 20, x + 11, 42), fill=(78, 79, 83, 210), outline=(181, 171, 141, 125))
    elif kind == "shrine":
        d.ellipse((38, 18, 58, 38), fill=(245, 231, 173, 185), outline=(255, 252, 218, 220), width=2)
        d.line((48, 36, 48, 49), fill=(255, 252, 218, 220), width=3)
    elif kind == "high":
        d.polygon([(16, 32), (48, 12), (80, 32), (48, 52)], outline=(222, 213, 157, 180), fill=None)
    save(img, path)


def overlay(path: Path, color: tuple[int, int, int], mark: str) -> None:
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    diamond(d, 48, 32, 88, 54, (*color, 72), (*color, 190), 3)
    if mark == "wet":
        d.ellipse((42, 20, 54, 42), fill=(*color, 165))
    elif mark == "burning":
        d.polygon([(48, 18), (59, 39), (48, 49), (37, 39)], fill=(255, 112, 45, 175))
    elif mark == "frozen":
        d.line((48, 17, 48, 47), fill=(224, 255, 255, 210), width=3)
        d.line((32, 32, 64, 32), fill=(224, 255, 255, 210), width=3)
    else:
        d.line((42, 17, 54, 30, 45, 31, 56, 47), fill=(244, 242, 118, 220), width=4)
    save(img, path)


def highlight(path: Path, color: tuple[int, int, int], inner: str) -> None:
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    diamond(d, 48, 32, 88, 54, (*color, 72), (*color, 230), 4)
    if inner == "selected":
        diamond(d, 48, 32, 40, 24, (255, 255, 255, 35), (255, 248, 196, 230), 2)
    elif inner == "blocked":
        d.line((31, 20, 65, 44), fill=(255, 248, 235, 230), width=5)
        d.line((65, 20, 31, 44), fill=(255, 248, 235, 230), width=5)
    else:
        d.ellipse((39, 23, 57, 41), outline=(255, 255, 255, 205), width=3)
    save(img, path)


def command_icon(path: Path, color: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((6, 6, 58, 58), radius=10, fill=(23, 25, 30, 242), outline=(*color, 255), width=3)
    if kind == "move":
        d.line((21, 34, 43, 34), fill=(*color, 255), width=5)
        d.polygon([(43, 24), (54, 34), (43, 44)], fill=(*color, 255))
    elif kind == "attack":
        d.line((20, 45, 45, 20), fill=(*color, 255), width=5)
        d.polygon([(42, 14), (50, 14), (50, 22)], fill=(*color, 255))
    elif kind == "ability":
        for i in range(8):
            a = i * pi / 4
            d.line((32, 32, 32 + cos(a) * 19, 32 + sin(a) * 19), fill=(*color, 210), width=2)
        d.ellipse((23, 23, 41, 41), fill=(*color, 225))
    elif kind == "item":
        d.polygon([(24, 18), (42, 18), (47, 43), (19, 43)], fill=(*color, 220), outline=(255, 246, 210, 180))
    else:
        d.ellipse((21, 21, 43, 43), outline=(*color, 255), width=5)
        d.line((32, 17, 32, 32), fill=(*color, 255), width=4)
    save(img, path)


def job_icon(path: Path, color: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(32, 5), (55, 18), (55, 46), (32, 59), (9, 46), (9, 18)], fill=(28, 25, 33, 240), outline=(*color, 255))
    if kind in {"knight", "guardian"}:
        d.polygon([(32, 17), (45, 24), (41, 45), (32, 51), (23, 45), (19, 24)], fill=(*color, 215))
    elif kind == "mage":
        d.ellipse((20, 18, 44, 42), outline=(*color, 255), width=4)
        d.line((32, 42, 32, 52), fill=(*color, 255), width=4)
    elif kind == "cleric":
        d.line((32, 16, 32, 50), fill=(*color, 255), width=6)
        d.line((21, 28, 43, 28), fill=(*color, 255), width=6)
    elif kind == "rogue":
        d.polygon([(18, 38), (46, 18), (38, 46)], fill=(*color, 225))
    else:
        d.arc((14, 15, 54, 55), -65, 65, fill=(*color, 255), width=5)
        d.line((36, 32, 51, 23), fill=(*color, 255), width=4)
    save(img, path)


def unit_token(path: Path, color: tuple[int, int, int], kind: str, enemy: bool = False) -> None:
    img = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((31, 101, 97, 118), fill=(0, 0, 0, 92))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    d = ImageDraw.Draw(img)
    outline = (74, 31, 55, 255) if enemy else (26, 54, 76, 255)
    d.ellipse((47, 20, 81, 54), fill=(226, 207, 176, 255), outline=outline, width=3)
    d.polygon([(38, 56), (90, 56), (100, 104), (28, 104)], fill=(*color, 240), outline=outline)
    if kind in {"zane", "kael", "knight", "guardian", "warder"}:
        d.line((35, 67, 93, 98), fill=(224, 215, 176, 255), width=6)
        d.polygon([(92, 94), (110, 110), (87, 106)], fill=(224, 215, 176, 255))
    elif kind in {"mira", "mage", "arcanist", "luminary"}:
        d.line((34, 38, 25, 102), fill=(189, 143, 83, 255), width=5)
        d.ellipse((17, 26, 33, 42), fill=(117, 205, 232, 220))
    elif kind in {"lyra", "archer", "skywarden"}:
        d.arc((29, 45, 83, 110), -80, 80, fill=(221, 194, 122, 255), width=5)
        d.line((44, 55, 91, 83), fill=(238, 235, 211, 255), width=3)
    else:
        d.ellipse((37, 45, 91, 101), outline=(204, 103, 226, 230), width=5)
        d.polygon([(64, 34), (89, 82), (64, 110), (39, 82)], fill=(*color, 195), outline=outline)
    save(img, path)


def portrait(path: Path, color: tuple[int, int, int], enemy: bool = False) -> None:
    img = Image.new("RGBA", (192, 192), (26, 24, 30, 255))
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 191, 191), outline=(205, 176, 112, 255), width=5)
    d.ellipse((48, 32, 144, 128), fill=(220, 199, 166, 255), outline=(69, 52, 52, 255), width=4)
    d.polygon([(38, 120), (154, 120), (181, 192), (11, 192)], fill=(*color, 255))
    eye = (178, 44, 83, 255) if enemy else (80, 170, 210, 255)
    d.ellipse((72, 78, 82, 88), fill=eye)
    d.ellipse((110, 78, 120, 88), fill=eye)
    save(img, path)


def vfx_sheet(path: Path, color: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    for i in range(4):
        d = ImageDraw.Draw(img)
        cx = 32 + i * 64
        r = 8 + i * 7
        d.ellipse((cx - r, 32 - r, cx + r, 32 + r), fill=(*color, 55 + i * 35), outline=(*color, 210), width=2)
        if kind == "damage":
            d.rectangle((cx - 12, 23, cx + 12, 41), fill=(255, 245, 188, 220), outline=(93, 34, 34, 255))
        else:
            d.line((cx - r, 32, cx + r, 32), fill=(255, 255, 255, 190), width=2)
            d.line((cx, 32 - r, cx, 32 + r), fill=(255, 255, 255, 190), width=2)
    save(img, path)


def status_icon(path: Path, color: tuple[int, int, int], mark: str) -> None:
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((4, 4, 44, 44), radius=8, fill=(25, 24, 30, 242), outline=(*color, 255), width=3)
    if mark == "poison":
        d.ellipse((18, 12, 30, 26), fill=(*color, 240))
        d.rectangle((21, 24, 27, 36), fill=(*color, 240))
    elif mark == "burn":
        d.polygon([(24, 10), (34, 28), (24, 39), (14, 28)], fill=(*color, 240))
    elif mark == "freeze":
        for a in (0, pi / 3, 2 * pi / 3):
            d.line((24 - cos(a) * 14, 24 - sin(a) * 14, 24 + cos(a) * 14, 24 + sin(a) * 14), fill=(*color, 240), width=3)
    elif mark == "stun":
        d.line((20, 10, 30, 23, 22, 23, 30, 38), fill=(*color, 240), width=4)
    elif mark == "silence":
        d.ellipse((14, 15, 34, 33), outline=(*color, 240), width=4)
        d.line((13, 36, 36, 12), fill=(*color, 240), width=4)
    elif mark == "haste":
        d.line((13, 30, 30, 13, 30, 25, 38, 25), fill=(*color, 240), width=4)
    elif mark == "slow":
        d.ellipse((14, 14, 34, 34), outline=(*color, 240), width=4)
        d.line((24, 17, 24, 25, 31, 29), fill=(*color, 240), width=3)
    elif mark == "regen":
        d.arc((12, 13, 36, 37), 35, 315, fill=(*color, 240), width=4)
        d.polygon([(34, 13), (39, 22), (29, 21)], fill=(*color, 240))
    elif mark == "guard-break":
        d.polygon([(24, 11), (35, 17), (32, 34), (24, 39), (16, 34), (13, 17)], outline=(*color, 240), width=4)
        d.line((17, 13, 31, 38), fill=(*color, 240), width=3)
    elif mark == "bleed":
        d.polygon([(24, 10), (34, 28), (24, 40), (14, 28)], fill=(*color, 240))
    elif mark == "curse":
        d.arc((13, 12, 35, 36), 20, 340, fill=(*color, 240), width=4)
        d.line((16, 16, 32, 32), fill=(*color, 240), width=3)
    else:
        d.ellipse((12, 12, 36, 36), outline=(*color, 240), width=5)
        d.ellipse((18, 18, 30, 30), fill=(*color, 160))
    save(img, path)


def cursor(path: Path, color: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(8, 5), (38, 24), (24, 29), (18, 43)], fill=(*color, 235), outline=(255, 250, 218, 255))
    if kind == "attack":
        d.line((25, 35, 42, 18), fill=(255, 250, 218, 255), width=3)
    elif kind == "magic":
        d.ellipse((28, 8, 43, 23), outline=(255, 250, 218, 255), width=3)
    save(img, path)


def generate_for(base: Path) -> None:
    tile_specs = {
        "grass-tile-placeholder.png": ((58, 105, 72), (136, 177, 105), "grass"),
        "dirt-tile-placeholder.png": ((107, 78, 54), (176, 137, 86), "dirt"),
        "stone-road-tile-placeholder.png": ((88, 84, 76), (184, 164, 118), "road"),
        "stone-floor-tile-placeholder.png": ((82, 82, 86), (166, 162, 144), "stone"),
        "wall-tile-placeholder.png": ((65, 67, 73), (160, 151, 128), "wall"),
        "water-tile-placeholder.png": ((44, 96, 121), (111, 202, 227), "water"),
        "shrine-tile-placeholder.png": ((92, 82, 92), (236, 220, 157), "shrine"),
        "high-ground-tile-placeholder.png": ((72, 91, 67), (190, 178, 120), "high"),
    }
    for name, (base_color, accent, kind) in tile_specs.items():
        tile(base / "tiles" / name, base_color, accent, kind)

    for name, color, mark in [
        ("wet-overlay-placeholder.png", (96, 188, 218), "wet"),
        ("burning-overlay-placeholder.png", (240, 90, 40), "burning"),
        ("frozen-overlay-placeholder.png", (166, 229, 248), "frozen"),
        ("electrified-overlay-placeholder.png", (240, 231, 92), "electrified"),
    ]:
        overlay(base / "tiles" / name, color, mark)

    for name, color, inner in [
        ("tile-selected-diamond.png", (240, 214, 105), "selected"),
        ("tile-move-diamond.png", (76, 190, 134), "move"),
        ("tile-attack-diamond.png", (222, 70, 75), "attack"),
        ("tile-ability-diamond.png", (120, 126, 232), "ability"),
        ("tile-blocked-diamond.png", (125, 119, 116), "blocked"),
    ]:
        highlight(base / "ui" / name, color, inner)

    for name, size in [
        ("dark-stone-panel.png", (240, 120)),
        ("command-bar-panel.png", (384, 80)),
        ("turn-order-sidebar-panel.png", (160, 420)),
    ]:
        panel(base / "ui" / name, size, (31, 31, 37), (190, 156, 91))

    for name, color in [
        ("hp-bar-frame.png", (171, 48, 55)),
        ("temper-bar-frame.png", (216, 139, 57)),
        ("ether-bar-frame.png", (83, 142, 219)),
    ]:
        bar_frame(base / "ui" / name, color)

    for name, color, kind in [
        ("command-move-icon.png", (86, 201, 147), "move"),
        ("command-attack-icon.png", (222, 70, 75), "attack"),
        ("command-ability-icon.png", (130, 132, 238), "ability"),
        ("command-item-icon.png", (215, 172, 83), "item"),
        ("command-wait-icon.png", (176, 187, 190), "wait"),
    ]:
        command_icon(base / "icons" / name, color, kind)

    for name, color, kind in [
        ("job-knight-icon.png", (211, 185, 107), "knight"),
        ("job-mage-icon.png", (123, 142, 232), "mage"),
        ("job-cleric-icon.png", (228, 218, 166), "cleric"),
        ("job-rogue-icon.png", (112, 204, 155), "rogue"),
        ("job-archer-icon.png", (132, 190, 111), "archer"),
        ("job-guardian-icon.png", (222, 155, 89), "guardian"),
    ]:
        job_icon(base / "icons" / name, color, kind)

    for name, color, kind in [
        ("fire-impact-vfx-sheet.png", (246, 92, 51), "fire"),
        ("ice-impact-vfx-sheet.png", (157, 226, 250), "ice"),
        ("lightning-impact-vfx-sheet.png", (243, 234, 95), "lightning"),
        ("earth-impact-vfx-sheet.png", (169, 124, 73), "earth"),
        ("wind-impact-vfx-sheet.png", (129, 218, 173), "wind"),
        ("damage-number-floats.png", (238, 64, 72), "damage"),
    ]:
        vfx_sheet(base / "vfx" / name, color, kind)

    unit_specs = [
        ("zane-idle-placeholder.png", (54, 126, 178), "zane", False),
        ("zane-action-placeholder.png", (64, 145, 200), "zane", False),
        ("mira-idle-placeholder.png", (88, 150, 208), "mira", False),
        ("mira-action-placeholder.png", (110, 183, 232), "mira", False),
        ("kael-idle-placeholder.png", (74, 116, 166), "kael", False),
        ("kael-action-placeholder.png", (92, 132, 190), "kael", False),
        ("null-drake-idle-placeholder.png", (112, 51, 142), "null-drake", True),
        ("null-drake-attack-placeholder.png", (150, 61, 166), "null-drake", True),
        ("storm-imp-idle-placeholder.png", (157, 59, 95), "storm-imp", True),
        ("storm-imp-attack-placeholder.png", (198, 70, 110), "storm-imp", True),
        ("fen-wraith-idle-placeholder.png", (95, 72, 146), "fen-wraith", True),
        ("fen-wraith-attack-placeholder.png", (120, 80, 182), "fen-wraith", True),
        ("titan-guardian-summon.png", (116, 92, 70), "guardian", False),
        ("siren-guardian-summon.png", (64, 139, 169), "mage", False),
    ]
    for name, color, kind, enemy in unit_specs:
        unit_token(base / "characters" / name, color, kind, enemy)

    for name, color, enemy in [
        ("zane-portrait-placeholder.png", (54, 126, 178), False),
        ("mira-portrait-placeholder.png", (88, 150, 208), False),
        ("kael-portrait-placeholder.png", (74, 116, 166), False),
    ]:
        portrait(base / "characters" / name, color, enemy)


def generate_manifest_pass() -> None:
    for name, color, kind in [
        ("selected-tile.png", (240, 214, 105), "selected"),
        ("move-range-tile.png", (76, 190, 134), "move"),
        ("attack-range-tile.png", (222, 70, 75), "attack"),
        ("magic-range-tile.png", (120, 126, 232), "ability"),
        ("objective-marker.png", (232, 190, 76), "selected"),
    ]:
        highlight(SRC / "ui" / "range-markers" / name, color, kind)

    for name, color, kind in [
        ("cursor-default.png", (228, 210, 148), "default"),
        ("cursor-attack.png", (222, 70, 75), "attack"),
        ("cursor-magic.png", (120, 126, 232), "magic"),
    ]:
        cursor(SRC / "ui" / "cursors" / name, color, kind)

    for name, color in [
        ("poison", (110, 198, 92)),
        ("burn", (241, 94, 52)),
        ("freeze", (164, 226, 250)),
        ("stun", (242, 222, 81)),
        ("silence", (176, 177, 192)),
        ("haste", (101, 222, 170)),
        ("slow", (126, 132, 166)),
        ("regen", (118, 211, 116)),
        ("guard-break", (218, 130, 78)),
        ("bleed", (198, 41, 65)),
        ("curse", (163, 77, 202)),
        ("barrier", (92, 159, 226)),
    ]:
        status_icon(SRC / "ui" / "status-icons" / f"status-icon-{name}.png", color, name)


def generate_game_placeholders() -> None:
    for name, color, kind, enemy in [
        ("zane_idle.png", (54, 126, 178), "zane", False),
        ("mira_idle.png", (88, 150, 208), "mira", False),
        ("warder_idle.png", (74, 116, 166), "warder", False),
        ("null_drake_idle.png", (112, 51, 142), "null-drake", True),
        ("storm_imp_idle.png", (157, 59, 95), "storm-imp", True),
        ("fen_wraith_idle.png", (95, 72, 146), "fen-wraith", True),
        ("void_golem_idle.png", (92, 68, 116), "guardian", True),
    ]:
        unit_token(GAME_PLACEHOLDERS / "units" / name, color, kind, enemy)

    for name, color, enemy in [
        ("zane.png", (54, 126, 178), False),
        ("mira.png", (88, 150, 208), False),
        ("kael.png", (74, 116, 166), False),
    ]:
        portrait(GAME_PLACEHOLDERS / "portraits" / name, color, enemy)


def main() -> None:
    generate_for(SRC)
    generate_manifest_pass()
    generate_game_placeholders()

    # Godot uses the same gameplay IDs but keeps assets under res://assets.
    for name, color, inner in [
        ("tile-selected-diamond.png", (240, 214, 105), "selected"),
        ("tile-move-diamond.png", (76, 190, 134), "move"),
        ("tile-attack-diamond.png", (222, 70, 75), "attack"),
        ("tile-ability-diamond.png", (120, 126, 232), "ability"),
        ("tile-blocked-diamond.png", (125, 119, 116), "blocked"),
    ]:
        highlight(GODOT / "ui" / name, color, inner)
    for name, size in [
        ("dark-stone-panel.png", (240, 120)),
        ("command-bar-panel.png", (384, 80)),
        ("turn-order-sidebar-panel.png", (160, 420)),
    ]:
        panel(GODOT / "ui" / name, size, (31, 31, 37), (190, 156, 91))
    for name, color in [
        ("hp-bar-frame.png", (171, 48, 55)),
        ("temper-bar-frame.png", (216, 139, 57)),
        ("ether-bar-frame.png", (83, 142, 219)),
    ]:
        bar_frame(GODOT / "ui" / name, color)

    for name, color, kind in [
        ("command-move-icon.png", (86, 201, 147), "move"),
        ("command-attack-icon.png", (222, 70, 75), "attack"),
        ("command-ability-icon.png", (130, 132, 238), "ability"),
        ("command-item-icon.png", (215, 172, 83), "item"),
        ("command-wait-icon.png", (176, 187, 190), "wait"),
        ("job-knight-icon.png", (211, 185, 107), "knight"),
        ("job-mage-icon.png", (123, 142, 232), "mage"),
        ("job-cleric-icon.png", (228, 218, 166), "cleric"),
        ("job-rogue-icon.png", (112, 204, 155), "rogue"),
        ("job-archer-icon.png", (132, 190, 111), "archer"),
        ("job-guardian-icon.png", (222, 155, 89), "guardian"),
    ]:
        if name.startswith("command"):
            command_icon(GODOT / "icons" / name, color, kind)
        else:
            job_icon(GODOT / "icons" / name, color, kind)

    for name, color, kind in [
        ("fire-impact-vfx-sheet.png", (246, 92, 51), "fire"),
        ("ice-impact-vfx-sheet.png", (157, 226, 250), "ice"),
        ("lightning-impact-vfx-sheet.png", (243, 234, 95), "lightning"),
        ("earth-impact-vfx-sheet.png", (169, 124, 73), "earth"),
        ("wind-impact-vfx-sheet.png", (129, 218, 173), "wind"),
        ("damage-number-floats.png", (238, 64, 72), "damage"),
    ]:
        vfx_sheet(GODOT / "vfx" / name, color, kind)

    for name, color, kind, enemy in [
        ("fen-wraith-idle-placeholder.png", (95, 72, 146), "fen-wraith", True),
        ("fen-wraith-attack-placeholder.png", (120, 80, 182), "fen-wraith", True),
        ("titan-guardian-summon.png", (116, 92, 70), "guardian", False),
        ("siren-guardian-summon.png", (64, 139, 169), "mage", False),
    ]:
        unit_token(GODOT / "characters" / name, color, kind, enemy)

    tile(GODOT / "tiles" / "wall-tile-placeholder.png", (65, 67, 73), (160, 151, 128), "wall")
    overlay(GODOT / "tiles" / "wet-overlay-placeholder.png", (96, 188, 218), "wet")
    overlay(GODOT / "tiles" / "electrified-overlay-placeholder.png", (240, 231, 92), "electrified")


if __name__ == "__main__":
    main()

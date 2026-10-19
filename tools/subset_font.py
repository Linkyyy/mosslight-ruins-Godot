#!/usr/bin/env python3
"""Optional font authoring tool; requires fontTools and a local Noto CJK source."""
from pathlib import Path
import argparse
import string


def main() -> None:
    from fontTools import subset
    from fontTools.ttLib import TTFont
    parser = argparse.ArgumentParser()
    parser.add_argument("font", type=Path)
    parser.add_argument("--font-number", type=int, default=2, help="SC index in the Noto CJK TTC")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    text = "".join(path.read_text(encoding="utf-8") for path in root.rglob("*.gd") if ".godot" not in path.parts)
    text += string.printable + "←→↑↓★☆✧✦◇◆✓—ⅠⅡⅢ＋−×●"
    font = TTFont(args.font, fontNumber=args.font_number)
    options = subset.Options()
    options.layout_features = ["*"]
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)
    for record in font["name"].names:
        if record.nameID in [1, 3, 4, 6]:
            name = "MosslightUI-Regular" if record.nameID in [3, 6] else "Mosslight UI"
            record.string = name.encode(record.getEncoding())
    target = root / "assets/fonts/MosslightUI.otf"
    font.save(target)
    print(f"Subset written: {target.name}, {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Bundle portable Windows files, notices, metadata and the installer icon."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    version = (ROOT / "release/version.txt").read_text().strip()
    output = ROOT / "builds/distribution"
    output.mkdir(parents=True, exist_ok=True)
    package = ROOT / "builds/windows"
    credits = package / "licenses"
    credits.mkdir(parents=True, exist_ok=True)
    shutil.copy(ROOT / "assets/fonts/LICENSE-Noto.txt", credits / "Noto-OFL.txt")
    for source in (ROOT / "assets/licenses").glob("Godot-*.txt"):
        shutil.copy(source, credits / source.name)
    shutil.copy(ROOT / "THIRD_PARTY_NOTICES.md", package / "THIRD_PARTY_NOTICES.md")
    (package / "README.txt").write_text(
        f"苔光遗境 · Mosslight {version}\n\n"
        "Windows 10/11 x64：直接运行 Mosslight.exe，无需安装 Godot。\n"
        "移动 A/D；跳跃 空格；攻击 J；施法 K；互动 E；冲刺 Shift；暂停 Esc。\n"
        "能力与武器需要探索获得，地图/背包/装备使用 M/B/I。\n"
        "F11 切换全屏。支持手柄，存档保存在系统用户数据目录。\n"
        "这是未购买代码签名证书的测试版，尚未进行完整设备兼容性验收。\n"
        "卸载程序保留玩家存档。\n\n"
        "项目与问题反馈：https://github.com/Linkyyy/mosslight-ruins-Godot\n",
        encoding="utf-8-sig")
    Image.open(ROOT / "builds/icon.png").save(ROOT / "builds/icon.ico", format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)], bitmap_format="bmp")
    archive_path = output / f"Mosslight-{version}-Windows-x64-Portable.zip"
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
        for source in sorted(package.rglob("*")):
            if source.is_file() and source.suffix != ".log":
                archive.write(source, Path("Mosslight") / source.relative_to(package))
    shutil.copy(ROOT / "builds/android/Mosslight.apk", output / f"Mosslight-{version}-Android-arm64.apk")
    (output / "BUILD-INFO.json").write_text(json.dumps({
        "version": version, "engine": "Godot 4.6.3 Standard", "source_commit": os.environ["GITHUB_SHA"],
        "android": "ARM64, debug signed preview, landscape, offline",
        "windows": "x64, unsigned per-user installer and portable application",
    }, ensure_ascii=False, indent=2) + "\n")


def checksums() -> None:
    output = ROOT / "builds/distribution"
    lines = [f"{hashlib.sha256(file.read_bytes()).hexdigest()}  {file.name}"
             for file in sorted(output.iterdir()) if file.is_file() and file.name != "SHA256SUMS.txt"]
    (output / "SHA256SUMS.txt").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    import sys
    checksums() if "--checksums" in sys.argv else main()

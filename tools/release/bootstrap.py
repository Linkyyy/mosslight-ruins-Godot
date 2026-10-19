#!/usr/bin/env python3
"""Install the exact official engine/templates with published SHA-256 checks."""
from pathlib import Path
import hashlib
import os
import shutil
import urllib.request
import zipfile

VERSION = "4.6.3"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
ASSETS = {
    f"Godot_v{VERSION}-stable_linux.x86_64.zip": "d0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3",
    f"Godot_v{VERSION}-stable_export_templates.tpz": "3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8",
}
TEMPLATES = ["version.txt", "android_debug.apk", "android_release.apk", "windows_release_x86_64.exe"]


def download(name: str, digest: str, folder: Path) -> Path:
    destination = folder / name
    if not destination.exists():
        print(f"Downloading {name}", flush=True)
        request = urllib.request.Request(f"{BASE}/{name}", headers={"User-Agent": "Mosslight-native-build"})
        temporary = destination.with_suffix(".partial")
        with urllib.request.urlopen(request, timeout=120) as source, temporary.open("wb") as target:
            shutil.copyfileobj(source, target)
        temporary.replace(destination)
    hasher = hashlib.sha256()
    with destination.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            hasher.update(chunk)
    if hasher.hexdigest() != digest:
        raise SystemExit(f"Checksum mismatch: {name}")
    return destination


def main() -> None:
    cache = Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "mosslight-engine"
    cache.mkdir(parents=True, exist_ok=True)
    archives = {name: download(name, checksum, cache) for name, checksum in ASSETS.items()}
    binary = cache / "bin"
    binary.mkdir(exist_ok=True)
    with zipfile.ZipFile(archives[f"Godot_v{VERSION}-stable_linux.x86_64.zip"]) as archive:
        engine = binary / "godot"
        engine.write_bytes(archive.read(f"Godot_v{VERSION}-stable_linux.x86_64"))
        engine.chmod(0o755)
    templates = Path(os.environ["XDG_DATA_HOME"]) / "godot/export_templates" / f"{VERSION}.stable"
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archives[f"Godot_v{VERSION}-stable_export_templates.tpz"]) as archive:
        for name in TEMPLATES:
            (templates / name).write_bytes(archive.read(f"templates/{name}"))
    with open(os.environ["GITHUB_PATH"], "a", encoding="utf-8") as path_file:
        path_file.write(f"{binary}\n")
    print(f"Verified engine and {len(TEMPLATES)} template files installed.")


if __name__ == "__main__":
    main()

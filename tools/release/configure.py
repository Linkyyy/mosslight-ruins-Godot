#!/usr/bin/env python3
"""Configure an isolated export profile; never write signing material to git."""
from pathlib import Path
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    version = (ROOT / "release/version.txt").read_text().strip()
    if not version or any(c not in "0123456789abcdefghijklmnopqrstuvwxyz.-" for c in version):
        raise SystemExit("Invalid release version")
    keystore = Path(os.environ["RUNNER_TEMP"]) / "mosslight-test-signing/debug.keystore"
    keystore.parent.mkdir(parents=True, exist_ok=True)
    if not keystore.exists():
        subprocess.run([
            "keytool", "-genkeypair", "-noprompt", "-keystore", str(keystore),
            "-storepass", "android", "-keypass", "android", "-alias", "androiddebugkey",
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
            "-dname", "CN=Mosslight Preview, O=Mosslight, C=CN",
        ], check=True)
    settings = Path(os.environ["XDG_CONFIG_HOME"]) / "godot/editor_settings-4.6.tres"
    settings.parent.mkdir(parents=True, exist_ok=True)
    properties = {
        "export/android/java_sdk_path": os.environ["JAVA_HOME"],
        "export/android/android_sdk_path": os.environ["ANDROID_HOME"],
        "export/android/debug_keystore": str(keystore),
        "export/android/debug_keystore_user": "androiddebugkey",
        "export/android/debug_keystore_pass": "android",
    }
    settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
                        "\n".join(f"{key} = {json.dumps(value)}" for key, value in properties.items()) + "\n")
    presets = ROOT / "export_presets.cfg"
    content = presets.read_text()
    content = content.replace('version/name="0.1.0"', f'version/name="{version}"')
    presets.write_text(content)
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as environment:
        environment.write(f"RELEASE_VERSION={version}\n")


if __name__ == "__main__":
    main()

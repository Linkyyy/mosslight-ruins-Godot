#!/usr/bin/env python3
"""Import and validate with the actual Godot engine in a disposable profile."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / ".user_test"


def run_engine(args: list[str], log_name: str, runtime: bool = False) -> None:
    binary = os.environ.get("GODOT_BIN") or shutil.which("godot") or shutil.which("godot4")
    if not binary:
        raise SystemExit("Godot 4.6.3 not found. Set GODOT_BIN to the executable path.")
    env = os.environ.copy()
    for name, folder in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
        destination = WORK / folder
        destination.mkdir(parents=True, exist_ok=True)
        env[name] = str(destination)
    command = [binary, "--headless", "--path", str(ROOT), *args]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=120)
    output = result.stdout + result.stderr
    (WORK / log_name).write_text(output, encoding="utf-8")
    fatal = r"SCRIPT ERROR|Parse Error|Failed to load script|FAILED:"
    if runtime:
        fatal += r"|ERROR:"
    if result.returncode or re.search(fatal, output):
        print(output)
        raise SystemExit(result.returncode or 1)
    if runtime:
        print(output.strip())


if __name__ == "__main__":
    run_engine(["--editor", "--import"], "import.log")
    run_engine(["res://tests/runner.tscn", "--", "--test-profile"], "regression.log", runtime=True)

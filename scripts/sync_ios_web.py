#!/usr/bin/env python3
from pathlib import Path
from shutil import copy2, copytree, rmtree

ROOT = Path(__file__).resolve().parents[1]
WEB_OUT = ROOT / "ios" / "BatalAlDroob" / "BatalAlDroob" / "Web"

FILES = [
    "index.html",
    "styles.css",
    "app.js",
    "manifest.webmanifest",
    "service-worker.js",
    "privacy.html",
    "support.html",
]


def main():
    WEB_OUT.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        copy2(ROOT / name, WEB_OUT / name)

    for folder in ["data", "assets", "catalog"]:
        destination = WEB_OUT / folder
        if destination.exists():
            rmtree(destination)
    (WEB_OUT / "data").mkdir()
    copy2(ROOT / "data" / "y60_app_catalog.json", WEB_OUT / "data" / "y60_app_catalog.json")
    copytree(ROOT / "assets", WEB_OUT / "assets")
    copytree(ROOT / "flutter_y60_catalog" / "assets" / "catalog", WEB_OUT / "catalog")
    print(f"Synced web app to {WEB_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

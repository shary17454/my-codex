#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = APP_ROOT / "BatalAlDroob" / "Web"
MANIFEST_PATH = WEB_ROOT / "data" / "patrol_full_catalog_files.json"
SEARCH_INDEX_PATH = WEB_ROOT / "catalog" / "search" / "catalog_search_index.json"


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"Cannot read {path}: {error}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate the complete Batal Al-Droob PDF catalog archive.")
    parser.add_argument(
        "--archive-root",
        type=Path,
        default=WEB_ROOT,
        help="Root containing catalog/patrol_full_unique (defaults to the app Web directory).",
    )
    parser.add_argument(
        "--full-hash",
        action="store_true",
        help="Read every PDF and verify its SHA-256; this can take several minutes.",
    )
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    archive_root = arguments.archive_root.expanduser().resolve()
    manifest = load_json(MANIFEST_PATH)
    search_index = load_json(SEARCH_INDEX_PATH)
    files = manifest.get("files")
    if not isinstance(files, list):
        fail("Manifest files must be an array")

    expected_paths: set[str] = set()
    generation_counts: dict[str, int] = {}
    total_bytes = 0
    for index, item in enumerate(files, start=1):
        if not isinstance(item, dict):
            fail(f"Manifest item {index} is not an object")
        relative_path = item.get("app_path")
        expected_hash = item.get("sha256")
        expected_bytes = item.get("bundled_bytes") or item.get("size_bytes")
        generation = item.get("generation", "unknown")
        if not isinstance(relative_path, str):
            fail(f"Manifest item {index} has no app_path")
        if relative_path in expected_paths:
            fail(f"Duplicate manifest path: {relative_path}")
        expected_paths.add(relative_path)
        file_path = archive_root / relative_path
        if not file_path.is_file():
            fail(f"Missing archive PDF: {relative_path}")
        actual_bytes = file_path.stat().st_size
        if not isinstance(expected_bytes, int) or actual_bytes != expected_bytes:
            fail(f"Size mismatch for {relative_path}: expected {expected_bytes}, found {actual_bytes}")
        if not isinstance(expected_hash, str) or len(expected_hash) != 64:
            fail(f"Invalid manifest SHA-256 for {relative_path}")
        if arguments.full_hash and sha256(file_path) != expected_hash:
            fail(f"SHA-256 mismatch for {relative_path}")
        total_bytes += actual_bytes
        generation_counts[generation] = generation_counts.get(generation, 0) + 1

    actual_paths = {
        str(path.relative_to(archive_root))
        for path in (archive_root / "catalog" / "patrol_full_unique").rglob("*.pdf")
    }
    if actual_paths != expected_paths:
        missing = sorted(expected_paths - actual_paths)
        extras = sorted(actual_paths - expected_paths)
        fail(f"Archive paths differ from manifest; missing={len(missing)}, extras={len(extras)}")

    entries = search_index.get("entries")
    if not isinstance(entries, list):
        fail("Search index entries must be an array")
    indexed_paths = {
        entry.get("sourcePdfPath")
        for entry in entries
        if isinstance(entry, dict) and entry.get("type") == "catalog_pdf"
    }
    if indexed_paths != expected_paths:
        fail("Search index PDF paths do not match the complete archive manifest")

    gibibytes = total_bytes / (1024 ** 3)
    hash_status = "verified" if arguments.full_hash else "skipped (use --full-hash)"
    print(
        "PASS: catalog archive is complete; "
        f"files={len(files)}, size={gibibytes:.2f} GiB, generations={generation_counts}, SHA-256={hash_status}."
    )


if __name__ == "__main__":
    main()

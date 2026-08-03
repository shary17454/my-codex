#!/usr/bin/env python3
"""Generate deterministic Apple-hosted Background Assets manifests for catalogs."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
from dataclasses import dataclass, field
from pathlib import Path


APP_ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = APP_ROOT / "BatalAlDroob" / "Web"
SOURCE_MANIFEST = WEB_ROOT / "data" / "patrol_full_catalog_files.json"
DELIVERY_MANIFEST = WEB_ROOT / "data" / "catalog_asset_delivery.json"
PACK_MANIFEST_DIRECTORY = APP_ROOT / "CatalogAssetPacks" / "manifests"
DEFAULT_OUTPUT_DIRECTORY = APP_ROOT / "CatalogAssetPacks" / "archives"
DEFAULT_TARGET_BYTES = 192 * 1024 * 1024


@dataclass
class Pack:
    identifier: str
    generation: str
    files: list[dict] = field(default_factory=list)
    total_bytes: int = 0

    def append(self, item: dict) -> None:
        self.files.append(item)
        self.total_bytes += int(item["size_bytes"])


def normalized_generation(value: object) -> str:
    raw = str(value or "unknown").upper()
    return raw if raw in {"Y60", "Y61", "Y62", "Y63"} else "UNKNOWN"


def normalized_years(item: dict) -> list[str]:
    values = item.get("years") or []
    return sorted({str(value) for value in values if str(value).isdigit()})


def validate_source_item(item: dict) -> None:
    required = ("id", "file_name", "app_path", "size_bytes", "sha256")
    missing = [key for key in required if not item.get(key)]
    if missing:
        raise ValueError(f"Catalog item {item.get('id', '<unknown>')} misses {missing}")
    path = str(item["app_path"])
    if not path.startswith("catalog/patrol_full_unique/") or ".." in Path(path).parts:
        raise ValueError(f"Unsafe catalog app path: {path}")
    if len(str(item["sha256"])) != 64:
        raise ValueError(f"Invalid SHA-256 for {item['id']}")


def normalized_source_item(item: dict, ordinal: int) -> dict:
    normalized = dict(item)
    normalized["id"] = str(
        item.get("id") or f"patrol_catalog_imported_{ordinal:04d}_{str(item.get('sha256', ''))[:12]}"
    )
    normalized["size_bytes"] = int(item.get("size_bytes") or item.get("bundled_bytes") or 0)
    return normalized


def build_packs(files: list[dict], target_bytes: int) -> list[Pack]:
    packs: list[Pack] = []
    counters: dict[str, int] = {}
    ordered = sorted(
        files,
        key=lambda item: (
            normalized_generation(item.get("generation")),
            normalized_years(item),
            str(item.get("file_name", "")).casefold(),
            str(item.get("id", "")),
        ),
    )

    for item in ordered:
        validate_source_item(item)
        generation = normalized_generation(item.get("generation"))
        current = packs[-1] if packs and packs[-1].generation == generation else None
        size = int(item["size_bytes"])
        if current is None or current.files and current.total_bytes + size > target_bytes:
            counters[generation] = counters.get(generation, 0) + 1
            identifier = f"batal.catalog.{generation.lower()}.{counters[generation]:03d}"
            current = Pack(identifier=identifier, generation=generation)
            packs.append(current)
        current.append(item)
    return packs


def pack_manifest(pack: Pack) -> dict:
    return {
        "assetPackID": pack.identifier,
        "downloadPolicy": {"onDemand": {}},
        "fileSelectors": [{"file": item["app_path"]} for item in pack.files],
        "platforms": ["iOS"],
    }


def delivery_entry(item: dict, pack: Pack) -> dict:
    return {
        "id": item["id"],
        "fileName": item["file_name"],
        "generation": normalized_generation(item.get("generation")),
        "years": normalized_years(item),
        "engines": sorted({str(value) for value in item.get("engines") or [] if value}),
        "modelCodes": sorted({str(value) for value in item.get("model_codes") or [] if value}),
        "markets": sorted({str(value) for value in item.get("markets") or [] if value}),
        "sourceKind": str(item.get("source_kind") or "catalog_pdf"),
        "pageCount": int(item.get("pages") or 0),
        "sizeBytes": int(item["size_bytes"]),
        "sha256": item["sha256"],
        "assetPackID": pack.identifier,
        "assetPath": item["app_path"],
        "sourceRelativePath": item.get("relative_path") or "",
    }


def generate(target_bytes: int) -> tuple[list[Pack], dict]:
    source = json.loads(SOURCE_MANIFEST.read_text(encoding="utf-8"))
    files = [normalized_source_item(item, index) for index, item in enumerate(source.get("files") or [], 1)]
    if len(files) != 640:
        raise ValueError(f"Expected 640 catalog files, found {len(files)}")

    packs = build_packs(files, target_bytes)
    if len(packs) > 200:
        raise ValueError(f"Apple allows at most 200 hosted packs; generated {len(packs)}")
    mapping = {item["id"]: pack for pack in packs for item in pack.files}
    if len(mapping) != len(files):
        raise ValueError("Every catalog must map to exactly one asset pack")

    generated_at = source.get("generated_at")
    if not isinstance(generated_at, str) or not generated_at:
        raise ValueError("Source manifest must provide a stable generated_at timestamp")
    delivery = {
        "schemaVersion": 1,
        "generatedAt": generated_at,
        "delivery": "apple_hosted_background_assets",
        "minimumManagedOS": "iOS 26.0",
        "totalFiles": len(files),
        "totalBytes": sum(int(item["size_bytes"]) for item in files),
        "packCount": len(packs),
        "targetPackBytes": target_bytes,
        "documents": [delivery_entry(item, mapping[item["id"]]) for item in files],
        "packs": [
            {
                "id": pack.identifier,
                "generation": pack.generation,
                "fileCount": len(pack.files),
                "uncompressedBytes": pack.total_bytes,
            }
            for pack in packs
        ],
    }
    return packs, delivery


def write_manifests(packs: list[Pack], delivery: dict) -> None:
    PACK_MANIFEST_DIRECTORY.mkdir(parents=True, exist_ok=True)
    for stale in PACK_MANIFEST_DIRECTORY.glob("*.json"):
        stale.unlink()
    for pack in packs:
        path = PACK_MANIFEST_DIRECTORY / f"{pack.identifier}.json"
        path.write_text(
            json.dumps(pack_manifest(pack), ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    DELIVERY_MANIFEST.write_text(
        json.dumps(delivery, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def resolved_ba_package() -> Path:
    explicit = os.environ.get("BA_PACKAGE")
    if explicit:
        tool = Path(explicit).expanduser().resolve()
        if tool.is_file():
            return tool
        raise FileNotFoundError(f"BA_PACKAGE does not point to a file: {tool}")

    developer_dir = os.environ.get("DEVELOPER_DIR")
    if developer_dir:
        tool = Path(developer_dir).expanduser().resolve() / "usr" / "bin" / "ba-package"
        if tool.is_file():
            return tool
        raise FileNotFoundError(f"ba-package is missing from DEVELOPER_DIR: {tool}")

    xcrun = shutil.which("xcrun")
    if not xcrun:
        raise FileNotFoundError("xcrun was not found; install a supported Xcode release")
    result = subprocess.run(
        [xcrun, "--find", "ba-package"],
        check=True,
        capture_output=True,
        text=True,
    )
    tool = Path(result.stdout.strip())
    if not tool.is_file():
        raise FileNotFoundError(f"xcrun returned an invalid ba-package path: {tool}")
    return tool


def package(pack_id: str, output_directory: Path, tool: Path) -> Path:
    manifest = PACK_MANIFEST_DIRECTORY / f"{pack_id}.json"
    if not manifest.exists():
        raise FileNotFoundError(f"Unknown generated pack: {pack_id}")
    output_directory.mkdir(parents=True, exist_ok=True)
    output = output_directory / f"{pack_id}.aar"
    if output.exists():
        output.unlink()
    subprocess.run(
        [str(tool), "package", str(manifest), "--output-path", str(output)],
        cwd=WEB_ROOT,
        check=True,
    )
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-mib", type=int, default=192)
    parser.add_argument("--package", dest="pack_id")
    parser.add_argument("--package-all", action="store_true")
    parser.add_argument("--output-directory", type=Path, default=DEFAULT_OUTPUT_DIRECTORY)
    args = parser.parse_args()
    if args.pack_id and args.package_all:
        parser.error("use either --package or --package-all")

    packs, delivery = generate(args.target_mib * 1024 * 1024)
    write_manifests(packs, delivery)
    print(
        f"generated files={delivery['totalFiles']} packs={delivery['packCount']} "
        f"bytes={delivery['totalBytes']}"
    )
    requested_pack_ids = [args.pack_id] if args.pack_id else []
    if args.package_all:
        requested_pack_ids = [pack.identifier for pack in packs]
    if requested_pack_ids:
        tool = resolved_ba_package()
        version = subprocess.run(
            [str(tool), "--version"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        print(f"packaging tool={tool} version={version}")
        for pack_id in requested_pack_ids:
            output = package(pack_id, args.output_directory, tool)
            print(f"packaged {output}")


if __name__ == "__main__":
    main()

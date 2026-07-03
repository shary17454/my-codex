from __future__ import annotations

import hashlib
import json
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "full_y61_iab"
CACHE = ROOT / "sources" / "partsouq" / "image_cache"


def cache_path(url: str) -> Path:
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".gif"
    return CACHE / f"{hashlib.sha1(url.encode('utf-8')).hexdigest()}{ext}"


def main() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    urls: list[str] = []
    for source in sorted(SRC.glob("*.progressive.json")):
        data = json.loads(source.read_text(encoding="utf-8-sig"))
        for unit in data.get("units", []):
            url = str(unit.get("diagram_image_url") or "").strip()
            if url:
                urls.append(url)
    unique_urls = sorted(set(urls))
    downloaded = 0
    existing = 0
    failed: list[dict[str, str]] = []
    opener = urllib.request.build_opener()
    opener.addheaders = [("User-Agent", "Mozilla/5.0")]
    for url in unique_urls:
        path = cache_path(url)
        if path.exists() and path.stat().st_size > 0:
            existing += 1
            continue
        try:
            with opener.open(url, timeout=30) as response:
                path.write_bytes(response.read())
            if path.exists() and path.stat().st_size > 0:
                downloaded += 1
            else:
                failed.append({"url": url, "error": "empty download"})
        except Exception as exc:
            failed.append({"url": url, "error": str(exc)})
    report = {
        "urls": len(unique_urls),
        "existing": existing,
        "downloaded": downloaded,
        "failed": len(failed),
        "failures": failed[:25],
    }
    (ROOT / "deliverables" / "Y61_status" / "y61_diagram_download_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

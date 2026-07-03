from __future__ import annotations

import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "sources" / "partsouq" / "full_patrol_safari"
CACHE = ROOT / "sources" / "partsouq" / "image_cache"


def cache_path(url: str) -> Path:
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".gif"
    return CACHE / (hashlib.sha1(url.encode("utf-8")).hexdigest() + ext)


def download(url: str) -> dict[str, object]:
    path = cache_path(url)
    if path.exists() and path.stat().st_size > 0:
        return {"url": url, "status": "cached", "bytes": path.stat().st_size}
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as response:
            data = response.read()
        path.write_bytes(data)
        return {"url": url, "status": "downloaded", "bytes": len(data)}
    except Exception as exc:
        return {"url": url, "status": "failed", "error": str(exc)}


def main() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    urls: list[str] = []
    for source in SRC_DIR.glob("*.json"):
        data = json.loads(source.read_text(encoding="utf-8"))
        for unit in data.get("units", []):
            url = unit.get("diagram_image_url")
            if url:
                urls.append(url)
    urls = sorted(set(urls))
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=24) as pool:
        for result in pool.map(download, urls):
            results.append(result)
    summary = {
        "total_urls": len(urls),
        "cached_or_downloaded": sum(1 for r in results if r["status"] in {"cached", "downloaded"}),
        "downloaded": sum(1 for r in results if r["status"] == "downloaded"),
        "failed": sum(1 for r in results if r["status"] == "failed"),
        "results": results,
    }
    out = ROOT / "output" / "reports" / "patrol_safari_image_cache_summary.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k != "results"} | {"report": str(out)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

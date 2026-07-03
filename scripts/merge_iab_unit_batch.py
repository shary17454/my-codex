from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target_json")
    parser.add_argument("batch_json")
    args = parser.parse_args()

    target = Path(args.target_json)
    if not target.is_absolute():
        target = ROOT / target
    batch = Path(args.batch_json)
    if not batch.is_absolute():
        batch = ROOT / batch

    data = json.loads(target.read_text(encoding="utf-8-sig"))
    payload = json.loads(batch.read_text(encoding="utf-8-sig"))
    existing = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
    added = 0
    for unit in payload.get("units", []):
        uid = str(unit.get("uid", ""))
        if uid and uid not in existing:
            data.setdefault("units", []).append(unit)
            existing.add(uid)
            added += 1
    discovered = len(data.get("discovered_units", []))
    data["failures"] = []
    data["complete"] = discovered > 0 and len(data.get("units", [])) >= discovered
    data["extracted_at"] = datetime.now(timezone.utc).isoformat()
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({
        "target": str(target),
        "batch": str(batch),
        "added": added,
        "units": len(data.get("units", [])),
        "discovered": discovered,
        "remaining": max(discovered - len(data.get("units", [])), 0),
        "complete": data["complete"],
        "batch_failures": len(payload.get("failures", [])),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

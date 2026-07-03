from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from fill_iab_missing_from_cdp import make_expr, uid_of_failure


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--chunk", type=int, default=5)
    parser.add_argument("--port", type=int, default=9222)
    args = parser.parse_args()

    path = Path(args.path)
    if not path.is_absolute():
        path = ROOT / path
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    existing = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
    failed_existing = {uid_of_failure(failure) for failure in data.get("failures", []) if uid_of_failure(failure)}
    targets = [
        unit for unit in data.get("discovered_units", [])
        if str(unit.get("uid", "")) not in existing and str(unit.get("uid", "")) not in failed_existing
    ]

    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")
    added = 0
    new_failures = 0
    for start in range(0, len(targets), args.chunk):
        chunk = targets[start : start + args.chunk]
        result = call(
            sock,
            90000 + start,
            "Runtime.evaluate",
            {"expression": make_expr(chunk), "awaitPromise": True, "returnByValue": True, "timeout": 180000},
        )
        inner = result.get("result", {}).get("result", {})
        if "exceptionDetails" in result or inner.get("subtype") == "error":
            units = []
            failures = [{"unit": target, "error": "Verification Required: CDP chunk failed"} for target in chunk]
        else:
            payload = json.loads(inner.get("value") or "{}")
            units = payload.get("units", [])
            failures = payload.get("failures", [])
        data.setdefault("units", []).extend(units)
        data.setdefault("failures", []).extend(failures)
        added += len(units)
        new_failures += len(failures)
        discovered = len(data.get("discovered_units", []))
        data["complete"] = discovered > 0 and len(data.get("units", [])) + len(data.get("failures", [])) >= discovered
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"start": start, "chunk": len(chunk), "units": len(units), "failures": len(failures), "saved_units": len(data.get("units", [])), "complete": data["complete"]}, ensure_ascii=False), flush=True)

    print(json.dumps({"targets": len(targets), "added": added, "new_failures": new_failures, "units": len(data.get("units", [])), "failures": len(data.get("failures", [])), "complete": data.get("complete")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

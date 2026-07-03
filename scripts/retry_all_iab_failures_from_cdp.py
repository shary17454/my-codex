from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from fill_iab_missing_from_cdp import make_expr, uid_of_failure


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "full_patrol_all_iab"


def retry_file(sock, path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    failures = [failure for failure in data.get("failures", []) if uid_of_failure(failure)]
    if not failures:
        return {"file": str(path), "targets": 0, "added": 0, "remaining_failures": 0}
    discovered_by_uid = {str(unit.get("uid", "")): unit for unit in data.get("discovered_units", []) if unit.get("uid")}
    targets = [discovered_by_uid.get(uid_of_failure(failure), failure["unit"]) for failure in failures]
    added_total = 0
    failed_by_uid: dict[str, dict] = {}
    for start in range(0, len(targets), 20):
        chunk = targets[start : start + 20]
        result = call(
            sock,
            5000 + start,
            "Runtime.evaluate",
            {
                "expression": make_expr(chunk),
                "awaitPromise": True,
                "returnByValue": True,
                "timeout": 420000,
            },
        )
        inner = result.get("result", {}).get("result", {})
        if "exceptionDetails" in result or inner.get("subtype") == "error":
            for target in chunk:
                failed_by_uid[str(target.get("uid", ""))] = {"unit": target, "error": "Verification Required: CDP chunk failed"}
            continue
        payload = json.loads(inner.get("value") or "{}")
        units = payload.get("units", [])
        data.setdefault("units", []).extend(units)
        added_total += len(units)
        for failure in payload.get("failures", []):
            failed_by_uid[uid_of_failure(failure)] = failure

    current_uids = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
    data["failures"] = [
        failure
        for uid, failure in failed_by_uid.items()
        if uid and uid not in current_uids
    ]
    discovered = len(data.get("discovered_units", []))
    data["complete"] = discovered > 0 and len(data.get("units", [])) + len(data.get("failures", [])) >= discovered
    data["extracted_at"] = datetime.now(timezone.utc).isoformat()
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"file": str(path), "targets": len(targets), "added": added_total, "remaining_failures": len(data.get("failures", []))}


def main() -> None:
    sock = connect(get_page_ws(9222, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")
    results = []
    for path in sorted(SRC.glob("*.progressive.json")):
        results.append(retry_file(sock, path))
        print(json.dumps(results[-1], ensure_ascii=False))
    print(json.dumps({
        "files": len(results),
        "targets": sum(r["targets"] for r in results),
        "added": sum(r["added"] for r in results),
        "remaining_failures": sum(r["remaining_failures"] for r in results),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

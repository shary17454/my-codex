from __future__ import annotations

import json
from pathlib import Path

from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
REMAINING = ROOT / "output" / "reports" / "Y60_1988_201350_remaining_units.json"


def main() -> None:
    units = json.loads(REMAINING.read_text(encoding="utf-8-sig"))
    url = units[0]["unit_url"]
    expr = f"""
(async () => {{
  const url = {json.dumps(url)};
  const response = await fetch(url, {{ credentials: 'include' }});
  const text = await response.text();
  return JSON.stringify({{
    status: response.status,
    length: text.length,
    title: (text.match(/<title>(.*?)<\\/title>/i) || [])[1] || '',
    challenge: /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(text),
    hasParts: /Number|Quantity|Applicable Models|Part Number/i.test(text),
    sample: text.replace(/\\s+/g, ' ').slice(0, 300)
  }});
}})()
"""
    sock = connect(get_page_ws(9222, "partsouq.com"))
    call(sock, 1, "Runtime.enable")
    result = call(
        sock,
        2,
        "Runtime.evaluate",
        {"expression": expr, "awaitPromise": True, "returnByValue": True, "timeout": 60000},
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

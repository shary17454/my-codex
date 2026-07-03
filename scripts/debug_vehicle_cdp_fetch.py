from __future__ import annotations

import json
from pathlib import Path

from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "sources" / "partsouq" / "patrol_extraction_queue.json"


def main() -> None:
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    item = next(x for x in queue if x["extract_id"] == "Y60_1988_201356")
    expr = f"""
(async () => {{
  const url = {json.dumps(item["vehicle_url"])};
  const response = await fetch(url, {{ credentials: 'include' }});
  const text = await response.text();
  const doc = new DOMParser().parseFromString(text, 'text/html');
  const clean = s => (s || '').replace(/\\s+/g, ' ').trim();
  const links = [...doc.querySelectorAll('a[href]')].map(a => ({{href:new URL(a.getAttribute('href'), url).href, text:clean(a.innerText)}}));
  return JSON.stringify({{
    status: response.status,
    length: text.length,
    title: doc.title,
    challenge: /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(text),
    vehicleLinks: links.filter(x => x.href.includes('/catalog/genuine/vehicle?')).slice(0,20),
    unitLinks: links.filter(x => x.href.includes('/catalog/genuine/unit?')).slice(0,20),
    allLinks: links.length,
    sample: clean(doc.body?.innerText || '').slice(0,1000)
  }});
}})()
"""
    sock = connect(get_page_ws(9222, "partsouq.com"))
    call(sock, 1, "Runtime.enable")
    result = call(sock, 2, "Runtime.evaluate", {"expression": expr, "awaitPromise": True, "returnByValue": True, "timeout": 60000})
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

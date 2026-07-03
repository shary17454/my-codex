from __future__ import annotations

import json
import time

from cdp_eval import call, connect, get_page_ws

from debug_vehicle_cdp_fetch import QUEUE


def main() -> None:
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    item = next(x for x in queue if x["extract_id"] == "Y60_1988_201356")
    sock = connect(get_page_ws(9222, "partsouq.com"))
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")
    call(sock, 3, "Page.navigate", {"url": item["vehicle_url"]})
    time.sleep(12)
    expr = """
JSON.stringify({
  title: document.title,
  url: location.href,
  body: (document.body?.innerText || '').replace(/\\s+/g, ' ').slice(0, 1000),
  challenge: /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(document.documentElement.innerHTML),
  vehicleLinks: [...document.querySelectorAll('a[href*="/catalog/genuine/vehicle?"]')].map(a=>({href:new URL(a.getAttribute('href'), location.href).href, text:(a.innerText||'').replace(/\\s+/g,' ').trim()})).slice(0,20),
  unitLinks: [...document.querySelectorAll('a[href*="/catalog/genuine/unit?"]')].map(a=>({href:new URL(a.getAttribute('href'), location.href).href, text:(a.innerText||'').replace(/\\s+/g,' ').trim()})).slice(0,20)
})
"""
    result = call(sock, 4, "Runtime.evaluate", {"expression": expr, "returnByValue": True, "timeout": 60000})
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

from __future__ import annotations

import json
import time
from pathlib import Path

from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "sources" / "partsouq" / "full_patrol_all_iab" / "Y60_1988_209849_General_Asia_LHD_PICKUP_A-CHASSIS_TD42_STD.progressive.json"


def main() -> None:
    data = json.loads(TARGET.read_text(encoding="utf-8-sig"))
    unit = data["discovered_units"][0]
    sock = connect(get_page_ws(9222, "partsouq.com"))
    sock.settimeout(120)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")
    call(sock, 3, "Page.navigate", {"url": unit["unit_url"]})
    time.sleep(12)
    expr = """
JSON.stringify({
  title: document.title,
  url: location.href,
  body: (document.body.innerText || '').replace(/\\s+/g,' ').slice(0,2000),
  tables: [...document.querySelectorAll('table')].map((t, idx)=>({
    idx,
    headers: [...t.querySelectorAll('th')].map(x=>(x.innerText||'').replace(/\\s+/g,' ').trim()),
    firstRows: [...t.querySelectorAll('tr')].slice(0,5).map(tr=>[...tr.children].map(td=>(td.innerText||'').replace(/\\s+/g,' ').trim()))
  })),
  links: [...document.querySelectorAll('a[href]')].slice(0,20).map(a=>({text:(a.innerText||'').replace(/\\s+/g,' ').trim(), href:a.href})),
  challenge: /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked|التحقق من الأمان/i.test(document.documentElement.innerHTML)
})
"""
    result = call(sock, 4, "Runtime.evaluate", {"expression": expr, "returnByValue": True, "timeout": 60000})
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

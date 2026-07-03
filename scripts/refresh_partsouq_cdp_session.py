from __future__ import annotations

import json
import time

from cdp_eval import call, connect, get_page_ws


def main() -> None:
    sock = connect(get_page_ws(9222, "partsouq.com"))
    sock.settimeout(120)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")
    call(sock, 3, "Page.navigate", {"url": "https://partsouq.com/en/catalog/genuine/locate?c=Nissan"})
    for i in range(6):
        time.sleep(10)
        result = call(
            sock,
            10 + i,
            "Runtime.evaluate",
            {
                "expression": "JSON.stringify({title:document.title,url:location.href,tables:document.querySelectorAll('table').length,body:(document.body?.innerText||'').replace(/\\s+/g,' ').slice(0,500),challenge:/cf_chl|challenge-platform|Just a moment|Verify you are human|blocked|التحقق من الأمان/i.test(document.documentElement.innerHTML)})",
                "returnByValue": True,
                "timeout": 30000,
            },
        )
        print(json.dumps({"attempt": i + 1, "result": result}, ensure_ascii=False))


if __name__ == "__main__":
    main()

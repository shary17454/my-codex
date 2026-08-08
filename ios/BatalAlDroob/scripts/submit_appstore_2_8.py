#!/usr/bin/env python3
"""Submit Batal Al-Droob 2.8 for App Review through the App Store Connect API.

Usage:
    python3 scripts/submit_appstore_2_8.py ISSUER_ID [--dry-run]

ISSUER_ID comes from App Store Connect > Users and Access > Integrations >
App Store Connect API. It is an account identifier, not a secret; the private
keys already live in ~/.appstoreconnect/private_keys.

What it does, in order, verifying each step before the next:
  1. Authenticates (tries each local AuthKey until one works).
  2. Finds the app by bundle id com.batalaldroob.parts.
  3. Creates App Store version 2.8 (or reuses it if it already exists).
  4. Writes the What's New text for ar-SA and en-US.
  5. Attaches the newest VALID build of train 2.8.
  6. Submits the version for review (review submission flow, with fallback to
     the legacy appStoreVersionSubmissions endpoint).

--dry-run stops after step 5 and prints what would be submitted.

The script never prints key material and sends nothing anywhere except
api.appstoreconnect.apple.com.
"""

import base64
import glob
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

BUNDLE_ID = "com.batalaldroob.parts"
VERSION = "2.8"
API = "https://api.appstoreconnect.apple.com"
KEY_DIR = os.path.expanduser("~/.appstoreconnect/private_keys")

WHATS_NEW_AR = """أسرع في البحث والتصفح

• البحث في الكتالوج صار أسرع بشكل ملموس: الكتابة لا تتقطع، والنتائج تظهر فورًا، والتمرير في القائمة سلس.
• الشاشة الرئيسية تفتح مباشرة بدون تعليق عند حساب أعداد الأقسام وبطاقات الأجيال.
• فتح الكتالوجات الأصلية لم يعد يجمّد الشاشة: يظهر مؤشر تحميل ويبقى بإمكانك الإغلاق في أي لحظة.

عشر لغات… مترجمة فعلًا

• شاشة الترحيب الأولى صارت تظهر بلغتك المختارة بدل الإنجليزية.
• أسماء الأقسام وشارات سبب النتيجة والمؤشرات الذكية ورسائل الطلب صارت مترجمة بالكامل للإسبانية والفرنسية والألمانية والروسية والبرتغالية والصينية والتركية والهندية.
• تصحيح اتجاه الأسهم في اللغات التي تُكتب من اليسار لليمين.

تفاصيل مفيدة

• سجل الصيانة صار يعرض تاريخ كل عملية، والطلبات المحفوظة تعرض تاريخها.

ملاحظة: أسماء القطع وأرقامها تبقى بالعربية والإنجليزية لأن الكتالوجات الأصلية منشورة بهما، وأرقام OEM محايدة لغويًا."""

WHATS_NEW_EN = """Faster search and browsing

• Catalog search is noticeably faster: typing no longer stutters, results appear immediately, and the results list scrolls smoothly.
• The home screen opens straight away instead of pausing while it counts categories and generation records.
• Opening an original catalog no longer freezes the screen. A loading indicator appears and you can close the reader at any moment.

Ten languages, actually translated

• The first-run welcome screen now appears in the language you picked instead of English.
• Category names, search reason badges, smart indicators, and part-request messages are now fully translated into Spanish, French, German, Russian, Portuguese, Simplified Chinese, Turkish, and Hindi.
• Fixed chevrons that pointed the wrong way in left-to-right languages.

Useful details

• The maintenance log now shows the date of each entry, and saved part requests show when they were created.

Note: part names and numbers stay Arabic/English because the source catalogs are published that way, and OEM numbers are language-neutral."""


def b64u(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def make_token(key_id: str, issuer: str, key_path: str) -> str:
    header = b64u(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"},
                             separators=(",", ":")).encode())
    now = int(time.time())
    payload = b64u(json.dumps(
        {"iss": issuer, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        separators=(",", ":")).encode())
    signing_input = f"{header}.{payload}"
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path],
                         input=signing_input.encode(), capture_output=True).stdout
    if not der:
        raise RuntimeError(f"signing failed for {key_id}")
    # DER ECDSA-Sig-Value -> raw r||s
    idx = 2 if der[1] & 0x80 == 0 else 2 + (der[1] & 0x7F)

    def read_int(buf, off):
        ln = buf[off + 1]
        val = buf[off + 2:off + 2 + ln]
        return val.lstrip(b"\x00").rjust(32, b"\x00"), off + 2 + ln

    r, off = read_int(der, idx)
    s, _ = read_int(der, off)
    return f"{signing_input}.{b64u(r + s)}"


class ASC:
    def __init__(self, token: str):
        self.token = token

    def call(self, method: str, path: str, body=None):
        req = urllib.request.Request(
            API + path, method=method,
            data=json.dumps(body).encode() if body is not None else None,
            headers={"Authorization": f"Bearer {self.token}",
                     "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                text = resp.read().decode()
                return resp.status, json.loads(text) if text else {}
        except urllib.error.HTTPError as err:
            text = err.read().decode()
            try:
                return err.code, json.loads(text)
            except json.JSONDecodeError:
                return err.code, {"raw": text[:400]}


def fail(step, status, body):
    detail = ""
    for e in (body or {}).get("errors", [])[:2]:
        detail += f"\n  - {e.get('title')}: {e.get('detail')}"
    sys.exit(f"FAILED at {step} (HTTP {status}){detail or json.dumps(body)[:300]}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv
    if len(args) != 1:
        sys.exit(__doc__)
    issuer = args[0].strip()

    # 1. Authenticate with whichever local key works.
    client = None
    for key_path in sorted(glob.glob(os.path.join(KEY_DIR, "AuthKey_*.p8"))):
        kid = os.path.basename(key_path)[8:-3]
        candidate = ASC(make_token(kid, issuer, key_path))
        status, _ = candidate.call("GET", "/v1/apps?limit=1")
        print(f"[1] key {kid}: HTTP {status}")
        if status == 200:
            client = candidate
            break
    if client is None:
        sys.exit("FAILED: no local key authenticates with this issuer id. "
                 "The keys may be revoked or expired — generate a new one in "
                 "App Store Connect > Users and Access > Integrations.")

    # 2. Find the app.
    status, body = client.call(
        "GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    if status != 200 or not body.get("data"):
        fail("finding app", status, body)
    app_id = body["data"][0]["id"]
    print(f"[2] app id: {app_id}")

    # 3. Create or reuse the 2.8 version.
    status, body = client.call(
        "GET",
        f"/v1/apps/{app_id}/appStoreVersions"
        f"?filter[versionString]={VERSION}&filter[platform]=IOS")
    if status != 200:
        fail("listing versions", status, body)
    if body.get("data"):
        version_id = body["data"][0]["id"]
        state = body["data"][0]["attributes"].get("appStoreState")
        print(f"[3] version {VERSION} exists (state {state}): {version_id}")
    else:
        status, body = client.call("POST", "/v1/appStoreVersions", {
            "data": {"type": "appStoreVersions",
                     "attributes": {"platform": "IOS", "versionString": VERSION},
                     "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
        if status not in (200, 201):
            fail("creating version", status, body)
        version_id = body["data"]["id"]
        print(f"[3] created version {VERSION}: {version_id}")

    # 4. What's New for ar-SA and en-US.
    status, body = client.call(
        "GET", f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    if status != 200:
        fail("listing localizations", status, body)
    notes = {"ar-SA": WHATS_NEW_AR, "en-US": WHATS_NEW_EN}
    for loc in body.get("data", []):
        locale = loc["attributes"]["locale"]
        if locale in notes:
            status, patch_body = client.call(
                "PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {
                    "data": {"type": "appStoreVersionLocalizations",
                             "id": loc["id"],
                             "attributes": {"whatsNew": notes.pop(locale)}}})
            if status != 200:
                fail(f"what's new ({locale})", status, patch_body)
            print(f"[4] what's new set for {locale}")
    for locale in notes:
        print(f"[4] WARNING: locale {locale} not configured on this version; skipped")

    # 5. Attach the newest VALID build of train 2.8.
    status, body = client.call(
        "GET",
        f"/v1/builds?filter[app]={app_id}"
        f"&filter[preReleaseVersion.version]={VERSION}"
        f"&filter[processingState]=VALID&sort=-version&limit=1")
    if status != 200 or not body.get("data"):
        fail("finding a VALID 2.8 build (still processing?)", status, body)
    build = body["data"][0]
    build_number = build["attributes"]["version"]
    status, patch_body = client.call(
        "PATCH", f"/v1/appStoreVersions/{version_id}/relationships/build",
        {"data": {"type": "builds", "id": build["id"]}})
    if status not in (200, 204):
        fail("attaching build", status, patch_body)
    print(f"[5] attached build {build_number}")

    if dry_run:
        print(f"DRY RUN: would submit version {VERSION} (build {build_number}) for review.")
        return

    # 6. Submit for review — modern reviewSubmissions flow, legacy fallback.
    status, body = client.call("POST", "/v1/reviewSubmissions", {
        "data": {"type": "reviewSubmissions",
                 "attributes": {"platform": "IOS"},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})
    if status in (200, 201):
        submission_id = body["data"]["id"]
        item_body = {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {
                        "data": {"type": "reviewSubmissions", "id": submission_id}
                    },
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version_id}
                    },
                },
            }
        }
        status, body = client.call("POST", "/v1/reviewSubmissionItems", item_body)
        if status not in (200, 201):
            fail("adding version to review submission", status, body)
        status, body = client.call(
            "PATCH", f"/v1/reviewSubmissions/{submission_id}", {
                "data": {"type": "reviewSubmissions", "id": submission_id,
                         "attributes": {"submitted": True}}})
        if status != 200:
            fail("confirming review submission", status, body)
        print(f"[6] SUBMITTED for review (submission {submission_id})")
    else:
        print(f"[6] reviewSubmissions returned {status}; trying legacy endpoint")
        status, body = client.call("POST", "/v1/appStoreVersionSubmissions", {
            "data": {"type": "appStoreVersionSubmissions",
                     "relationships": {"appStoreVersion": {
                         "data": {"type": "appStoreVersions", "id": version_id}}}}})
        if status not in (200, 201):
            fail("legacy submission", status, body)
        print("[6] SUBMITTED for review (legacy endpoint)")

    print(f"\nDone: {VERSION} (build {build_number}) is waiting for review.")


if __name__ == "__main__":
    main()

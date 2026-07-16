#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "ios" / "BatalAlDroob"
PROJECT = APP_ROOT / "BatalAlDroob.xcodeproj" / "project.pbxproj"
INFO_PLIST = APP_ROOT / "BatalAlDroob" / "Info.plist"
APP_SWIFT = APP_ROOT / "BatalAlDroob" / "AppDelegate.swift"
WEB_ROOT = APP_ROOT / "BatalAlDroob" / "Web"

EXPECTED_MARKETING_VERSION = "1.1.0"
EXPECTED_BUILD = "92"
EXPECTED_BUNDLE_ID = "com.batalaldroob.parts"
ALLOWED_STOREKIT_PRODUCTS = {"batal.catalog.unlock"}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    sys.exit(1)


def unique_setting_values(project_text: str, key: str) -> set[str]:
    return set(re.findall(rf"{re.escape(key)} = ([^;]+);", project_text))


def main() -> None:
    project_text = PROJECT.read_text(encoding="utf-8")
    info_text = INFO_PLIST.read_text(encoding="utf-8")
    app_text = APP_SWIFT.read_text(encoding="utf-8")
    web_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in WEB_ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in {".html", ".js", ".json", ".css"}
    )

    marketing_values = unique_setting_values(project_text, "MARKETING_VERSION")
    build_values = unique_setting_values(project_text, "CURRENT_PROJECT_VERSION")
    bundle_values = unique_setting_values(project_text, "PRODUCT_BUNDLE_IDENTIFIER")

    if marketing_values != {EXPECTED_MARKETING_VERSION}:
        fail(f"MARKETING_VERSION must be {EXPECTED_MARKETING_VERSION}; found {sorted(marketing_values)}")
    if build_values != {EXPECTED_BUILD}:
        fail(f"CURRENT_PROJECT_VERSION must be {EXPECTED_BUILD}; found {sorted(build_values)}")
    if EXPECTED_BUNDLE_ID not in bundle_values:
        fail(f"Expected bundle id {EXPECTED_BUNDLE_ID}; found {sorted(bundle_values)}")

    if "$(MARKETING_VERSION)" not in info_text:
        fail("Info.plist must derive CFBundleShortVersionString from MARKETING_VERSION")
    if "$(CURRENT_PROJECT_VERSION)" not in info_text:
        fail("Info.plist must derive CFBundleVersion from CURRENT_PROJECT_VERSION")

    product_ids = set(re.findall(r'"(batal\.[a-zA-Z0-9_.-]+)"', app_text + "\n" + web_text))
    unexpected_products = {pid for pid in product_ids if pid.startswith("batal.")} - ALLOWED_STOREKIT_PRODUCTS
    if unexpected_products:
        fail(f"Unexpected StoreKit product ids found: {sorted(unexpected_products)}")

    forbidden_terms = [
        "batal.parts.request",
        "buyRequestPlan",
        "priceSAR",
        "priceSar",
        "رسوم الطلب",
        "Request fee",
        "دفع الرسوم",
        "Pay and prepare request",
        "Pay fee and prepare request",
        "after payment",
        "بعد الدفع",
    ]
    for term in forbidden_terms:
        if term in app_text or term in web_text:
            fail(f"Forbidden paid request term still exists: {term}")

    print("PASS: Batal Al-Droob release settings and StoreKit surface are valid.")


if __name__ == "__main__":
    main()

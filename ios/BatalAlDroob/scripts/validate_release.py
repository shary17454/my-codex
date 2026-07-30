#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
APP_ROOT = ROOT / "ios" / "BatalAlDroob"
PROJECT = APP_ROOT / "BatalAlDroob.xcodeproj" / "project.pbxproj"
INFO_PLIST = APP_ROOT / "BatalAlDroob" / "Info.plist"
PRIVACY_MANIFEST = APP_ROOT / "BatalAlDroob" / "PrivacyInfo.xcprivacy"
APPLE_ENGINEERING_STANDARD = APP_ROOT / "docs" / "APPLE_ENGINEERING_STANDARD.md"
SWIFT_ROOT = APP_ROOT / "BatalAlDroob"
WEB_ROOT = APP_ROOT / "BatalAlDroob" / "Web"

EXPECTED_MARKETING_VERSION = "2.1"
MIN_EXPECTED_BUILD = 149
EXPECTED_BUNDLE_ID = "com.batalaldroob.parts"
EXPECTED_PROJECT_BUNDLE_IDS = {
    "com.batalaldroob.parts",
    "com.batalaldroob.parts.tests",
    "com.batalaldroob.parts.uitests",
}
EXPECTED_DEPLOYMENT_TARGET = "17.0"
ALLOWED_STOREKIT_PRODUCTS = {
    "batal.catalog.single.unlock",
    "batal.catalog.full.unlock",
    "batal.catalog.permanent.unlock",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    sys.exit(1)


def unique_setting_values(project_text: str, key: str) -> set[str]:
    return set(re.findall(rf"{re.escape(key)} = ([^;]+);", project_text))


def main() -> None:
    if not APPLE_ENGINEERING_STANDARD.exists():
        fail("Apple engineering standard must exist at docs/APPLE_ENGINEERING_STANDARD.md")
    standard_text = APPLE_ENGINEERING_STANDARD.read_text(encoding="utf-8")
    if "Permanent engineering standard for this project." not in standard_text:
        fail("Apple engineering standard must remain the approved project constitution")

    project_text = PROJECT.read_text(encoding="utf-8")
    with INFO_PLIST.open("rb") as stream:
        info = plistlib.load(stream)
    with PRIVACY_MANIFEST.open("rb") as stream:
        privacy = plistlib.load(stream)
    app_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in SWIFT_ROOT.rglob("*.swift")
        if path.is_file()
    )
    web_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in WEB_ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in {".html", ".js", ".json", ".css"}
    )

    marketing_values = unique_setting_values(project_text, "MARKETING_VERSION")
    build_values = unique_setting_values(project_text, "CURRENT_PROJECT_VERSION")
    bundle_values = unique_setting_values(project_text, "PRODUCT_BUNDLE_IDENTIFIER")
    deployment_values = unique_setting_values(project_text, "IPHONEOS_DEPLOYMENT_TARGET")
    sdkroot_values = unique_setting_values(project_text, "SDKROOT")

    if marketing_values != {EXPECTED_MARKETING_VERSION}:
        fail(f"MARKETING_VERSION must be {EXPECTED_MARKETING_VERSION}; found {sorted(marketing_values)}")
    if len(build_values) != 1:
        fail(f"CURRENT_PROJECT_VERSION must be unified; found {sorted(build_values)}")
    build_value = next(iter(build_values))
    if not build_value.isdigit() or int(build_value) < MIN_EXPECTED_BUILD:
        fail(f"CURRENT_PROJECT_VERSION must be numeric and >= {MIN_EXPECTED_BUILD}; found {build_value}")
    if bundle_values != EXPECTED_PROJECT_BUNDLE_IDS:
        fail(f"Unexpected project bundle ids; found {sorted(bundle_values)}")
    if deployment_values != {EXPECTED_DEPLOYMENT_TARGET}:
        fail(f"IPHONEOS_DEPLOYMENT_TARGET must remain {EXPECTED_DEPLOYMENT_TARGET}; found {sorted(deployment_values)}")
    if sdkroot_values != {"iphoneos"}:
        fail(f"SDKROOT must be iphoneos; found {sorted(sdkroot_values)}")
    if "LM_FILTER_WARNINGS = YES;" in project_text:
        fail("Release settings must not hide linker metadata warnings with LM_FILTER_WARNINGS")
    if unique_setting_values(project_text, "EXTRACT_APP_INTENTS_METADATA") != {"NO"}:
        fail("The app target must disable unused App Intents metadata extraction explicitly")

    if info.get("CFBundleIdentifier") != "$(PRODUCT_BUNDLE_IDENTIFIER)":
        fail("Info.plist must derive CFBundleIdentifier from PRODUCT_BUNDLE_IDENTIFIER")
    if info.get("CFBundleShortVersionString") != "$(MARKETING_VERSION)":
        fail("Info.plist must derive CFBundleShortVersionString from MARKETING_VERSION")
    if info.get("CFBundleVersion") != "$(CURRENT_PROJECT_VERSION)":
        fail("Info.plist must derive CFBundleVersion from CURRENT_PROJECT_VERSION")
    if info.get("NSLocationWhenInUseUsageDescription"):
        fail("Info.plist must not request location permission; map and compass features are not part of this app")

    accessed_types = {
        item.get("NSPrivacyAccessedAPIType")
        for item in privacy.get("NSPrivacyAccessedAPITypes", [])
    }
    if "NSPrivacyAccessedAPICategoryUserDefaults" not in accessed_types:
        fail("Privacy manifest must declare the UserDefaults required-reason API")
    collected_types = {
        item.get("NSPrivacyCollectedDataType")
        for item in privacy.get("NSPrivacyCollectedDataTypes", [])
    }
    if collected_types:
        fail(f"The app must not declare collected data types; found {sorted(collected_types)}")
    if privacy.get("NSPrivacyTracking") is not False:
        fail("Privacy manifest must declare that the app does not track users")
    if not (APP_ROOT / "docs" / "APP_STORE_REVIEW_FIX_PLAN.md").exists():
        fail("App Store review fix plan must exist for metadata and IAP manual gates")

    forbidden_weather_terms = [
        "api.open-meteo.com",
        "OpenMeteoWeatherService",
        "OpenMeteoWeatherCurrent",
    ]
    for term in forbidden_weather_terms:
        if term.lower() in app_text.lower():
            fail(f"External weather integration must not return: {term}")
    forbidden_navigation_terms = [
        "import MapKit",
        "import CoreLocation",
        "LocationTrackingViewModel",
        "NSLocationWhenInUseUsageDescription",
    ]
    for term in forbidden_navigation_terms:
        if term.lower() in app_text.lower() or term.lower() in project_text.lower():
            fail(f"Map, compass, and location tracking code must not return: {term}")

    forbidden_version_mutators = [
        r"\bagvtool\b",
        r"PlistBuddy.*\bSet\b.*CFBundle(?:ShortVersionString|Version)",
        r"defaults\s+write.*CFBundle(?:ShortVersionString|Version)",
    ]
    ci_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (ROOT / "ci_scripts").glob("*.sh")
        if path.is_file()
    )
    for pattern in forbidden_version_mutators:
        if re.search(pattern, ci_text, flags=re.IGNORECASE):
            fail(f"CI must not mutate app version or build using pattern: {pattern}")

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
        "رسوم العميل",
        "طلب قطعة مدفوع",
        "ادفع رسوم طلب",
        "10 ر.س",
        "20 ر.س",
        "50 ر.س",
        "Request fee",
        "Paid Part Request",
        "Pay a small request fee",
        "Customer fee",
        "part request fee",
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

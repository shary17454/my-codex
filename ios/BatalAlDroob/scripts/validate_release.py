#!/usr/bin/env python3
from __future__ import annotations

import json
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
CATALOG_MANIFEST = WEB_ROOT / "data" / "patrol_full_catalog_files.json"
CATALOG_SEARCH_INDEX = WEB_ROOT / "catalog" / "search" / "catalog_search_index.json"
CATALOG_ASSET_DELIVERY = WEB_ROOT / "data" / "catalog_asset_delivery.json"
CATALOG_ASSET_MANIFESTS = APP_ROOT / "CatalogAssetPacks" / "manifests"
STORE_DIRECTORY = WEB_ROOT / "data" / "store_directory.json"
APP_ENTITLEMENTS = APP_ROOT / "BatalAlDroob" / "BatalAlDroob.entitlements"
ASSET_EXTENSION_INFO = APP_ROOT / "BatalCatalogAssetsExtension" / "Info.plist"
ASSET_EXTENSION_ENTITLEMENTS = (
    APP_ROOT / "BatalCatalogAssetsExtension" / "BatalCatalogAssetsExtension.entitlements"
)

EXPECTED_MARKETING_VERSION = "2.7"
MIN_EXPECTED_BUILD = 191
EXPECTED_BUNDLE_ID = "com.batalaldroob.parts"
EXPECTED_APP_GROUP = "group.com.batalaldroob.parts"
EXPECTED_PROJECT_BUNDLE_IDS = {
    "com.batalaldroob.parts",
    "com.batalaldroob.parts.catalogassets",
    "com.batalaldroob.parts.tests",
    "com.batalaldroob.parts.uitests",
}
EXPECTED_DEPLOYMENT_TARGETS = {"17.0", "26.0"}
ALLOWED_STOREKIT_PRODUCTS = {
    "batal.catalog.single.unlock",
    "batal.catalog.full.unlock",
    "batal.catalog.permanent.unlock",
}
EXPECTED_CATALOG_COUNTS = {
    "Y60": 297,
    "Y61": 143,
    "Y62": 140,
    "unknown": 60,
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    sys.exit(1)


def unique_setting_values(project_text: str, key: str) -> set[str]:
    return set(re.findall(rf"{re.escape(key)} = ([^;]+);", project_text))


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"Unable to read valid JSON from {path.relative_to(APP_ROOT)}: {error}")


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
    with APP_ENTITLEMENTS.open("rb") as stream:
        app_entitlements = plistlib.load(stream)
    with ASSET_EXTENSION_INFO.open("rb") as stream:
        asset_extension_info = plistlib.load(stream)
    with ASSET_EXTENSION_ENTITLEMENTS.open("rb") as stream:
        asset_extension_entitlements = plistlib.load(stream)
    catalog_manifest = read_json(CATALOG_MANIFEST)
    catalog_search = read_json(CATALOG_SEARCH_INDEX)
    catalog_delivery = read_json(CATALOG_ASSET_DELIVERY)
    store_directory = read_json(STORE_DIRECTORY)
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
    if deployment_values != EXPECTED_DEPLOYMENT_TARGETS:
        fail(
            "The app must remain on iOS 17 while the managed asset extension requires iOS 26; "
            f"found {sorted(deployment_values)}"
        )
    if sdkroot_values != {"iphoneos"}:
        fail(f"SDKROOT must be iphoneos; found {sorted(sdkroot_values)}")
    if "LM_FILTER_WARNINGS = YES;" in project_text:
        fail("Release settings must not hide linker metadata warnings with LM_FILTER_WARNINGS")
    if unique_setting_values(project_text, "EXTRACT_APP_INTENTS_METADATA") != {"NO"}:
        fail("The app target must disable unused App Intents metadata extraction explicitly")
    if "path = Web/catalog/search;" not in project_text or "path = Web/catalog;" in project_text:
        fail("The app resources must include only the catalog search index, never the PDF archive")
    for required_project_term in (
        "BatalCatalogAssetsExtension",
        "com.apple.product-type.extensionkit-extension",
        "BackgroundAssets.framework",
        "BatalAlDroob/BatalAlDroob.entitlements",
    ):
        if required_project_term not in project_text:
            fail(f"Managed catalog delivery project wiring is missing: {required_project_term}")

    test_resources = re.search(
        r"107000000000000000000002 /\* Resources \*/ = \{.*?files = \((.*?)\);",
        project_text,
        flags=re.DOTALL,
    )
    if not test_resources or test_resources.group(1).strip():
        fail("The unit-test target must reuse the app resources instead of copying the catalog a second time")

    catalog_files = catalog_manifest.get("files")
    if not isinstance(catalog_files, list) or len(catalog_files) != sum(EXPECTED_CATALOG_COUNTS.values()):
        fail("Catalog manifest must contain exactly 640 archived PDF records")

    manifest_paths: set[str] = set()
    generation_counts = {generation: 0 for generation in EXPECTED_CATALOG_COUNTS}
    for index, item in enumerate(catalog_files):
        if not isinstance(item, dict):
            fail(f"Catalog manifest item {index} must be an object")
        app_path = item.get("app_path")
        sha256 = item.get("sha256")
        generation = item.get("generation", "unknown")
        byte_count = item.get("bundled_bytes") or item.get("size_bytes")
        if not isinstance(app_path, str) or not app_path.startswith("catalog/patrol_full_unique/") or not app_path.endswith(".pdf"):
            fail(f"Catalog manifest item {index} has an invalid app_path")
        if app_path in manifest_paths:
            fail(f"Catalog manifest contains a duplicate app_path: {app_path}")
        manifest_paths.add(app_path)
        if not isinstance(sha256, str) or re.fullmatch(r"[0-9a-f]{64}", sha256) is None:
            fail(f"Catalog manifest item {index} is missing a valid SHA-256: {app_path}")
        if not isinstance(byte_count, int) or byte_count <= 0:
            fail(f"Catalog manifest item {index} has an invalid byte count: {app_path}")
        if item.get("bundled") is not True:
            fail(f"Catalog manifest item {index} is not marked available: {app_path}")
        generation_counts[generation if generation in generation_counts else "unknown"] += 1

    if generation_counts != EXPECTED_CATALOG_COUNTS:
        fail(f"Catalog generation counts differ from the approved inventory: {generation_counts}")

    delivery_documents = catalog_delivery.get("documents")
    delivery_packs = catalog_delivery.get("packs")
    if (
        catalog_delivery.get("schemaVersion") != 1
        or catalog_delivery.get("delivery") != "apple_hosted_background_assets"
        or catalog_delivery.get("minimumManagedOS") != "iOS 26.0"
        or catalog_delivery.get("totalFiles") != 640
        or not isinstance(delivery_documents, list)
        or len(delivery_documents) != 640
        or not isinstance(delivery_packs, list)
        or catalog_delivery.get("packCount") != len(delivery_packs)
        or not (0 < len(delivery_packs) <= 200)
    ):
        fail("Apple-hosted catalog delivery manifest is incomplete or invalid")
    pack_ids = {
        pack.get("id")
        for pack in delivery_packs
        if isinstance(pack, dict) and isinstance(pack.get("id"), str)
    }
    if len(pack_ids) != len(delivery_packs):
        fail("Catalog asset pack identifiers must be unique")
    if len(list(CATALOG_ASSET_MANIFESTS.glob("*.json"))) != len(pack_ids):
        fail("Every Apple-hosted catalog pack must have a packaging manifest")
    delivery_paths: set[str] = set()
    delivered_bytes = 0
    for index, document in enumerate(delivery_documents):
        if not isinstance(document, dict):
            fail(f"Catalog delivery document {index} must be an object")
        asset_path = document.get("assetPath")
        pack_id = document.get("assetPackID")
        sha256 = document.get("sha256")
        size_bytes = document.get("sizeBytes")
        if asset_path not in manifest_paths:
            fail(f"Catalog delivery document {index} has an unknown asset path: {asset_path}")
        if asset_path in delivery_paths:
            fail(f"Catalog delivery contains a duplicate asset path: {asset_path}")
        if pack_id not in pack_ids:
            fail(f"Catalog delivery document {index} references an unknown pack: {pack_id}")
        if not isinstance(sha256, str) or re.fullmatch(r"[0-9a-f]{64}", sha256) is None:
            fail(f"Catalog delivery document {index} has an invalid checksum")
        if not isinstance(size_bytes, int) or size_bytes <= 0:
            fail(f"Catalog delivery document {index} has an invalid size")
        delivery_paths.add(asset_path)
        delivered_bytes += size_bytes
    if delivery_paths != manifest_paths:
        fail("Apple-hosted asset packs must cover every catalog PDF exactly once")
    if delivered_bytes != catalog_delivery.get("totalBytes"):
        fail("Apple-hosted asset byte totals do not match the catalog inventory")

    store_policy = store_directory.get("policy")
    if not isinstance(store_policy, dict) or store_policy.get("removed_or_revoked_suppliers_are_excluded") is not True:
        fail("Store policy must exclude removed or revoked suppliers")
    serialized_store_directory = json.dumps(store_directory, ensure_ascii=False).lower()
    for removed_supplier_term in (
        "enhanced offroad solutions",
        "enhancedoffroadsolutions.com.au",
    ):
        if removed_supplier_term in serialized_store_directory:
            fail(f"Removed supplier must not return to the bundled directory: {removed_supplier_term}")
    if '\"/api/stores\"' in web_text:
        fail("The app must not replace the approved bundled store directory with a remote supplier list")

    search_entries = catalog_search.get("entries")
    if not isinstance(search_entries, list):
        fail("Catalog search index must contain an entries array")
    pdf_entries = [entry for entry in search_entries if isinstance(entry, dict) and entry.get("type") == "catalog_pdf"]
    search_paths = {entry.get("sourcePdfPath") for entry in pdf_entries}
    if len(pdf_entries) != len(catalog_files) or search_paths != manifest_paths:
        fail("Catalog search PDF entries must match every manifest path exactly")

    if info.get("CFBundleIdentifier") != "$(PRODUCT_BUNDLE_IDENTIFIER)":
        fail("Info.plist must derive CFBundleIdentifier from PRODUCT_BUNDLE_IDENTIFIER")
    if info.get("CFBundleShortVersionString") != "$(MARKETING_VERSION)":
        fail("Info.plist must derive CFBundleShortVersionString from MARKETING_VERSION")
    if info.get("CFBundleVersion") != "$(CURRENT_PROJECT_VERSION)":
        fail("Info.plist must derive CFBundleVersion from CURRENT_PROJECT_VERSION")
    if (
        info.get("BAAppGroupID") != EXPECTED_APP_GROUP
        or info.get("BAHasManagedAssetPacks") is not True
        or info.get("BAUsesAppleHosting") is not True
    ):
        fail("Info.plist must enable Apple-hosted managed Background Assets")
    if app_entitlements.get("com.apple.security.application-groups") != [EXPECTED_APP_GROUP]:
        fail("The app must use only the approved catalog App Group")
    if asset_extension_entitlements.get("com.apple.security.application-groups") != [EXPECTED_APP_GROUP]:
        fail("The catalog extension must use the same approved App Group")
    extension_attributes = asset_extension_info.get("EXAppExtensionAttributes", {})
    if extension_attributes.get("EXExtensionPointIdentifier") != "com.apple.background-asset-downloader-extension":
        fail("The catalog extension must use Apple's Background Asset downloader extension point")
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
    unexpected_products = (
        {pid for pid in product_ids if pid.startswith("batal.")}
        - ALLOWED_STOREKIT_PRODUCTS
        - pack_ids
    )
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

    forbidden_guest_terms = [
        "case guest",
        ".guest",
        "continueAsGuest",
        "متابعة كضيف",
        "Continue as guest",
        "onboarding.customer.guest",
    ]
    for term in forbidden_guest_terms:
        if term in app_text:
            fail(f"Guest entry must not return to the app: {term}")

    for required_identifier in [
        "onboarding.customer.register",
        "onboarding.customer.signin",
        "permissions.skip",
    ]:
        if required_identifier not in app_text:
            fail(f"Required onboarding control is missing: {required_identifier}")

    print("PASS: Batal Al-Droob release, account, catalog, and StoreKit surfaces are valid.")


if __name__ == "__main__":
    main()

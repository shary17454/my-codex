#!/usr/bin/env python3
import json
import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "StudyVault"
PROJECT_FILE = ROOT / "StudyVault.xcodeproj" / "project.pbxproj"

ALLOWED_CATEGORIES = {
    "all",
    "phones",
    "cars",
    "restaurants",
    "laptops",
    "services",
    "subscriptions",
    "gaming",
    "travel",
    "education",
    "home",
    "fashion",
    "health",
    "other",
}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_(message: str) -> None:
    print(f"PASS: {message}")


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"Cannot read JSON {path}: {exc}")


def validate_seed_questions() -> None:
    questions = load_json(APP_DIR / "SeedQuestions.json")
    if not isinstance(questions, list) or not questions:
        fail("SeedQuestions.json must contain a non-empty list")

    titles = set()
    for index, question in enumerate(questions, start=1):
        title = str(question.get("title", "")).strip()
        details = str(question.get("details", "")).strip()
        category = question.get("category")
        options = question.get("options")
        comments = question.get("comments", [])

        if not title:
            fail(f"Question #{index} has an empty title")
        if title in titles:
            fail(f"Duplicate question title: {title}")
        titles.add(title)
        if not details:
            fail(f"Question '{title}' has empty details")
        if category not in ALLOWED_CATEGORIES - {"all"}:
            fail(f"Question '{title}' has invalid category: {category}")
        if not isinstance(options, list) or len(options) < 2:
            fail(f"Question '{title}' must have at least two options")
        option_titles = []
        for option in options:
            option_title = str(option.get("title", "")).strip()
            if not option_title:
                fail(f"Question '{title}' has an empty option title")
            option_titles.append(option_title.casefold())
            votes = option.get("votes", 0)
            if not isinstance(votes, int) or votes < 0:
                fail(f"Question '{title}' option '{option_title}' has invalid votes")
        if len(option_titles) != len(set(option_titles)):
            fail(f"Question '{title}' has duplicate options")
        if not isinstance(comments, list):
            fail(f"Question '{title}' comments must be a list")
    pass_(f"SeedQuestions.json validated ({len(questions)} questions)")


def validate_product_knowledge() -> None:
    items = load_json(APP_DIR / "ProductKnowledge.json")
    if not isinstance(items, list) or not items:
        fail("ProductKnowledge.json must contain a non-empty list")

    ids = set()
    for index, item in enumerate(items, start=1):
        item_id = str(item.get("id", "")).strip()
        name = str(item.get("name", "")).strip()
        category = item.get("category")
        tags = item.get("tags", [])
        specs = item.get("specs", {})
        if not item_id:
            fail(f"Knowledge item #{index} has empty id")
        if item_id in ids:
            fail(f"Duplicate knowledge id: {item_id}")
        ids.add(item_id)
        if not name:
            fail(f"Knowledge item '{item_id}' has empty name")
        if category not in ALLOWED_CATEGORIES - {"all"}:
            fail(f"Knowledge item '{item_id}' has invalid category: {category}")
        if not isinstance(tags, list):
            fail(f"Knowledge item '{item_id}' tags must be a list")
        if not isinstance(specs, dict):
            fail(f"Knowledge item '{item_id}' specs must be a dictionary")
    pass_(f"ProductKnowledge.json validated ({len(items)} items)")


def validate_info_plist() -> None:
    with (APP_DIR / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)

    if info.get("CFBundleDisplayName") != "وش الرأي":
        fail("CFBundleDisplayName must be وش الرأي")
    if info.get("CFBundleShortVersionString") != "$(MARKETING_VERSION)":
        fail("CFBundleShortVersionString must derive from MARKETING_VERSION")
    if info.get("CFBundleVersion") != "$(CURRENT_PROJECT_VERSION)":
        fail("CFBundleVersion must derive from CURRENT_PROJECT_VERSION")
    if info.get("NSSupportsLiveActivities") is not None:
        fail("NSSupportsLiveActivities must not be declared without an ActivityKit implementation")
    if info.get("NSSupportsLiveActivitiesFrequentUpdates") is not None:
        fail("NSSupportsLiveActivitiesFrequentUpdates must not be declared without an ActivityKit implementation")
    schemes = [
        scheme
        for url_type in info.get("CFBundleURLTypes", [])
        for scheme in url_type.get("CFBundleURLSchemes", [])
    ]
    if "weshalray" not in schemes:
        fail("weshalray URL scheme is missing")
    pass_("Info.plist validated")


def validate_project_settings() -> None:
    project = PROJECT_FILE.read_text(encoding="utf-8")
    expected_pairs = {
        "PRODUCT_BUNDLE_IDENTIFIER": "com.shary17454.esal",
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    }
    for key, expected in expected_pairs.items():
        pattern = rf"{re.escape(key)} = {re.escape(expected)};"
        if not re.search(pattern, project):
            fail(f"{key} must be {expected}")
    if "BatalAlDroob" in project:
        fail("StudyVault project must not reference BatalAlDroob")
    pass_("Xcode project settings validated")


def main() -> None:
    validate_seed_questions()
    validate_product_knowledge()
    validate_info_plist()
    validate_project_settings()
    print("Wesh Alray data validation complete.")


if __name__ == "__main__":
    main()

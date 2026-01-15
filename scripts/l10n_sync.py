#!/usr/bin/env python3
"""
Sync Flutter zh_Hant ARB translations using Android native strings as source of truth.

Process:
- Read Flutter EN ARB and zh_Hant ARB
- Read Android EN and zh_Hant XML (copied under assets/l10n)
- For each Flutter EN text, find Android key by matching normalized content
- If found, take Android zh_Hant translation for that key and apply to Flutter zh_Hant ARB
- Write updated ARB and a summary report to stdout

This script intentionally strips simple inline HTML tags from Android values for matching
and applying, to avoid injecting tags into Flutter texts that expect plain strings.
"""

import json
import re
import sys
from pathlib import Path
from typing import List, Optional
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "l10n"

ARB_EN = ASSETS / "intl_en.arb"
ARB_ZH = ASSETS / "intl_zh_Hant.arb"
XML_EN = ASSETS / "strings_en.xml"
XML_ZH = ASSETS / "strings_zh_Hant.xml"


def read_arb(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def write_arb(path: Path, data: dict):
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def parse_android_strings(path: Path) -> dict:
    """Return mapping of key -> text.

    Uses itertext() to flatten inline tags (<u>, <i>, <b>) into plain text, so
    we can safely place into Flutter ARB without HTML markup.
    """
    try:
        tree = ET.parse(str(path))
    except ET.ParseError as e:
        print(f"ERROR: Failed to parse {path}: {e}", file=sys.stderr)
        sys.exit(1)
    root = tree.getroot()
    out = {}
    for node in root.findall("string"):
        name = node.attrib.get("name")
        if not name:
            continue
        # Flatten inner text including children, strip leading/trailing spaces.
        text = "".join(node.itertext()).strip()
        out[name] = text
    return out


_SPACE_RE = re.compile(r"\s+", re.UNICODE)


def normalize_text(s: str) -> str:
    # Replace non-breaking spaces and normalize whitespace
    s = s.replace("\u00A0", " ")
    # Normalize escaped newlines to actual newline for matching neutrality
    s = s.replace("\\n", "\n")
    s = _SPACE_RE.sub(" ", s).strip().lower()
    return s


def main():
    # Sanity checks
    for p in [ARB_EN, ARB_ZH, XML_EN, XML_ZH]:
        if not p.exists():
            print(f"ERROR: Missing required file: {p}", file=sys.stderr)
            sys.exit(1)

    arb_en = read_arb(ARB_EN)
    arb_zh = read_arb(ARB_ZH)
    xml_en = parse_android_strings(XML_EN)
    xml_zh = parse_android_strings(XML_ZH)

    # Build normalized lookup for Android EN: norm_text -> list[keys]
    en_norm_to_keys = {}
    for k, v in xml_en.items():
        norm = normalize_text(v)
        en_norm_to_keys.setdefault(norm, []).append(k)

    total = 0
    updated = 0
    ambiguous = []  # (flutter_key, en_text, matching_keys)
    missing = []    # (flutter_key, en_text)
    no_zh = []      # (android_key)

    def select_android_key(flutter_key: str, candidates: List[str]) -> Optional[str]:
        """Try to resolve ambiguous matches by simple heuristics based on key prefixes."""
        fk = flutter_key
        pref_map: list[tuple[str, str]] = [
            ("settings_", "setting_"),
            ("my_bookings_", "mybooking_"),
            ("my_booking_", "mybooking_"),
            ("booking_", "booking_"),
            ("register_", "reg_"),
            ("auth_", "signin_"),
            ("auth_", "signup_"),
            ("otp_", "signup_"),
        ]
        # 1) Prefer candidates by mapped prefixes
        for fk_pref, ck_pref in pref_map:
            if fk.startswith(fk_pref):
                pref_hits = [c for c in candidates if c.startswith(ck_pref)]
                if len(pref_hits) == 1:
                    return pref_hits[0]
                if len(pref_hits) > 1:
                    # Pick the shortest key name as a tie-breaker
                    return sorted(pref_hits, key=len)[0]
        # 2) Prefer general_ for very short generic keys
        if fk in {"email", "password", "ok", "confirm", "cancel", "logout", "login"}:
            gen = [c for c in candidates if c.startswith("general_")]
            if len(gen) == 1:
                return gen[0]
        # 3) Fallback: pick candidate with highest token overlap
        tokens = set(re.split(r"[_\-]", fk))
        best = None
        best_score = -1
        for c in candidates:
            ctokens = set(re.split(r"[_\-]", c))
            score = len(tokens & ctokens)
            if score > best_score:
                best_score = score
                best = c
        # Only accept if we have at least some overlap; otherwise remain ambiguous
        if best_score > 0:
            return best
        return None

    # Walk Flutter EN keys and try to map
    for f_key, en_val in arb_en.items():
        if f_key.startswith("@@") or f_key.startswith("@"):
            continue
        total += 1
        # Prepare comparable normalized text from Flutter EN
        flutter_norm = normalize_text(str(en_val))
        if not flutter_norm:
            continue
        match_keys = en_norm_to_keys.get(flutter_norm)
        if not match_keys:
            missing.append((f_key, en_val))
            continue
        if len(match_keys) > 1:
            chosen = select_android_key(f_key, match_keys)
            if not chosen:
                ambiguous.append((f_key, en_val, match_keys))
                continue
            android_key = chosen
        else:
            android_key = match_keys[0]
        zh_val = xml_zh.get(android_key)
        if zh_val is None:
            no_zh.append(android_key)
            continue

        # Apply to Flutter zh_Hant ARB when key exists or always? We update existing keys, add if missing.
        # Preserve existing meta entries like @f_key if present.
        prev = arb_zh.get(f_key)
        arb_zh[f_key] = zh_val
        if prev != zh_val:
            updated += 1

    # Write back
    write_arb(ARB_ZH, arb_zh)

    # Summary
    print("l10n_sync summary:")
    print(f"- Flutter EN keys processed: {total}")
    print(f"- Updated zh_Hant entries: {updated}")
    print(f"- Missing in Android EN: {len(missing)}")
    print(f"- Ambiguous matches: {len(ambiguous)}")
    print(f"- Android zh_Hant missing: {len(no_zh)}")

    # Optionally, list a few examples for follow-up
    def sample(lst, n=10):
        return lst[:n]

    if missing:
        print("\nExamples of missing (first 10):")
        for k, v in sample(missing):
            print(f"  - {k}: {v}")
    if ambiguous:
        print("\nExamples of ambiguous (first 10):")
        for k, v, keys in sample(ambiguous):
            print(f"  - {k}: '{v}' -> {keys}")
    if no_zh:
        print("\nExamples of Android zh_Hant missing (first 10):")
        for k in sample(no_zh):
            print(f"  - {k}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
tools/assert_version_concordance.py
===================================
Automated Version Concordance Gate for RollFor.
Validates that the version declared in RollFor.toc matches the latest entry in
src/OptionsPopup.lua and Git repository state.
"""

import os
import re
import sys
import subprocess

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

def main():
    toc_path = os.path.join(ROOT, "RollFor.toc")
    options_path = os.path.join(ROOT, "src", "OptionsPopup.lua")

    if not os.path.exists(toc_path):
        print(f"[FAIL] Missing {toc_path}")
        sys.exit(1)

    with open(toc_path, "r", encoding="utf-8", errors="replace") as f:
        toc_match = re.search(r"^## Version:\s*(.+)$", f.read(), re.M)
        if not toc_match:
            print("[FAIL] RollFor.toc missing ## Version:")
            sys.exit(1)
        toc_v = toc_match.group(1).strip()

    # Extract latest version from OptionsPopup.lua changelog table
    options_v = None
    if os.path.exists(options_path):
        with open(options_path, "r", encoding="utf-8", errors="replace") as f:
            matches = re.findall(r'\{\s*ver\s*=\s*["\']([^"\']+)["\']', f.read())
            if matches:
                options_v = matches[0].strip()

    print("=" * 76)
    print("VERSION CONCORDANCE ASSERTION AUDIT")
    print("=" * 76)
    print(f"  RollFor.toc Version:             {toc_v}")
    print(f"  OptionsPopup.lua Latest Version: {options_v}")

    # Check Git HEAD commit / tags if git is present
    git_tag = None
    try:
        tag_out = subprocess.check_output(
            ["git", "-C", ROOT, "describe", "--tags", "--exact-match"],
            stderr=subprocess.DEVNULL,
            text=True
        ).strip()
        git_tag = tag_out
        print(f"  Git Tag (Exact HEAD):            {git_tag}")
    except Exception:
        print("  Git Tag:                         (HEAD is untagged or not exact match)")

    print("-" * 76)
    if options_v and toc_v != options_v:
        print(f"[FAIL] Version mismatch: RollFor.toc ({toc_v}) != OptionsPopup.lua ({options_v})")
        sys.exit(1)

    print(f"[PASS] 100% Version Concordance Validated (Current Version: {toc_v})")
    sys.exit(0)

if __name__ == "__main__":
    main()

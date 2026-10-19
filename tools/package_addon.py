#!/usr/bin/env python3
"""
tools/package_addon.py
======================
Automated release packager and packaging hygiene validator for RollFor.
Ensures zero developer tooling, zero tests, zero dev binaries, and zero dotfiles
contaminate end-user release ZIP archives.
"""

import os
import sys
import zipfile

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_NAME = "RollFor"
ROOT_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
OUTPUT_ZIP = os.path.join(ROOT_DIR, f"{ADDON_NAME}.zip")

# Allowed extensions in release artifact
ALLOWED_EXTENSIONS = {".lua", ".toc", ".xml", ".tga", ".txt", ".md"}

# Explicitly forbidden directories and patterns
FORBIDDEN_SUBSTRINGS = ["tools/", "test/", "tests/", "__pycache__", ".git", ".github", ".agents"]
FORBIDDEN_EXTENSIONS = {".py", ".exe", ".dll", ".sh", ".json", ".yml", ".yaml"}

def get_whitelisted_files():
    """Returns list of relative files that belong in the distribution."""
    toc_path = os.path.join(ROOT_DIR, f"{ADDON_NAME}.toc")
    if not os.path.exists(toc_path):
        raise FileNotFoundError(f"Missing {toc_path}")

    files = [f"{ADDON_NAME}.toc"]

    # Parse RollFor.toc for declared modules
    with open(toc_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                mod_file = line.replace("\\", "/")
                if os.path.exists(os.path.join(ROOT_DIR, mod_file)):
                    if mod_file not in files:
                        files.append(mod_file)

    # Core metadata and root files
    root_inclusions = ["Bindings.xml", "README.md", "main.lua"]
    for r in root_inclusions:
        if os.path.exists(os.path.join(ROOT_DIR, r)) and r not in files:
            files.append(r)

    # Assets & libs directories
    for sub in ["assets", "libs"]:
        sub_dir = os.path.join(ROOT_DIR, sub)
        if os.path.exists(sub_dir):
            for root, dirs, fnames in os.walk(sub_dir):
                for fn in fnames:
                    full = os.path.join(root, fn)
                    rel = os.path.relpath(full, ROOT_DIR).replace("\\", "/")
                    if "bcc" not in rel.lower() and "/tests/" not in rel.lower() and rel not in files:
                        _, ext = os.path.splitext(fn)
                        if ext.lower() in ALLOWED_EXTENSIONS and ext.lower() not in FORBIDDEN_EXTENSIONS:
                            files.append(rel)

    return sorted(files)

def build_package():
    files_to_pack = get_whitelisted_files()
    print("=" * 76)
    print(f"PACKAGING RELEASE ARTIFACT: {ADDON_NAME}.zip")
    print("=" * 76)
    print(f"Target Addon Root:  {ROOT_DIR}")
    print(f"Output Archive:     {OUTPUT_ZIP}")
    print(f"Whitelisted files ({len(files_to_pack)}):")

    if os.path.exists(OUTPUT_ZIP):
        os.remove(OUTPUT_ZIP)

    with zipfile.ZipFile(OUTPUT_ZIP, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in files_to_pack:
            disk_path = os.path.join(ROOT_DIR, f)
            archive_path = f"{ADDON_NAME}/{f}"
            zf.write(disk_path, archive_path)

    print(f"\nCreated {OUTPUT_ZIP} ({os.path.getsize(OUTPUT_ZIP):,} bytes)")
    return OUTPUT_ZIP

def audit_package(zip_path):
    print("\n" + "=" * 76)
    print("RELEASE PACKAGING HYGIENE AUDIT")
    print("=" * 76)

    with zipfile.ZipFile(zip_path, "r") as zf:
        entries = zf.namelist()
        total_entries = len(entries)
        print(f"Inspecting {total_entries} entries in archive...")

        violations = []
        for entry in entries:
            # Check 1: Root directory invariant
            if not entry.startswith(f"{ADDON_NAME}/"):
                violations.append(f"Root path violation (must start with {ADDON_NAME}/): {entry}")

            # Check 2: Forbidden substrings
            for forbidden in FORBIDDEN_SUBSTRINGS:
                if forbidden in entry.lower():
                    violations.append(f"Forbidden directory/component '{forbidden}' in: {entry}")

            # Check 3: Forbidden extensions
            _, ext = os.path.splitext(entry)
            if ext.lower() in FORBIDDEN_EXTENSIONS:
                violations.append(f"Forbidden file extension '{ext}' in: {entry}")

            # Check 4: Allowed extensions
            if ext.lower() not in ALLOWED_EXTENSIONS:
                violations.append(f"Unapproved file extension '{ext}' in: {entry}")

        if violations:
            print(f"[FAIL] Hygiene violations detected ({len(violations)}):")
            for v in violations:
                print(f"  - {v}")
            return False

        print(f"[PASS] 100% Release Packaging Hygiene Verified (0 developer leaks across {total_entries} files)")
        return True

def main():
    audit_only = "--audit-only" in sys.argv
    if audit_only:
        # Check files directly against hygiene rules
        files = get_whitelisted_files()
        print("=" * 76)
        print("PRE-PACKAGING HYGIENE AUDIT (DRY-RUN)")
        print("=" * 76)
        violations = []
        for f in files:
            for forbidden in FORBIDDEN_SUBSTRINGS:
                if forbidden in f.lower():
                    violations.append(f"Forbidden substring '{forbidden}' in: {f}")
            _, ext = os.path.splitext(f)
            if ext.lower() in FORBIDDEN_EXTENSIONS:
                violations.append(f"Forbidden extension '{ext}' in: {f}")
        if violations:
            print(f"[FAIL] {len(violations)} violations found")
            for v in violations:
                print(f"  - {v}")
            sys.exit(1)
        print(f"[PASS] All {len(files)} whitelisted distribution files comply with hygiene standards.")
        sys.exit(0)

    zip_file = build_package()
    ok = audit_package(zip_file)
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()

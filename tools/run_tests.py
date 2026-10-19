#!/usr/bin/env python3
"""
tools/run_tests.py
==================
RollFor Automated Verification Suite Runner.
Coordinates all core gates, native compilers, version assertions, and SR+ pipelines:

Gate 1: tools/check_lua50_syntax.py         (Native Lua 5.0.3 Compiler Syntax Audit)
Gate 2: tools/assert_version_concordance.py (Version Concordance Audit)
Gate 3: tools/test_sr_plus_pipeline.py      (SR+ Data Pipeline & Arithmetic Gauntlet)
Gate 4: tools/package_addon.py --audit-only (Release Packaging Hygiene Gate)

Exits with 0 if all gates pass, 1 if any gate fails.
"""

import os
import subprocess
import sys
import time

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

GATES = [
    ("Native Lua 5.0.3 Compiler Syntax Audit", [sys.executable, os.path.join(SCRIPT_DIR, "check_lua50_syntax.py")]),
    ("Version Concordance Assertion Audit", [sys.executable, os.path.join(SCRIPT_DIR, "assert_version_concordance.py")]),
    ("SR+ Data Pipeline & Arithmetic Gauntlet", [sys.executable, os.path.join(SCRIPT_DIR, "test_sr_plus_pipeline.py")]),
    ("Release Packaging Hygiene Gate", [sys.executable, os.path.join(SCRIPT_DIR, "package_addon.py"), "--audit-only"]),
]

def main():
    print("=" * 80)
    print("ROLLFOR AUTOMATED VERIFICATION SUITE")
    print("=" * 80)

    total_start = time.time()
    all_passed = True
    results = []

    for name, cmd in GATES:
        print(f"\n>>> Running {name}...")
        start_t = time.time()
        res = subprocess.run(cmd, cwd=ADDON_ROOT, capture_output=True, text=True, check=False)
        duration = time.time() - start_t

        output = (res.stdout or "") + (res.stderr or "")
        lines = [l for l in output.strip().splitlines() if l.strip()]
        for l in lines[-6:]:
            print(f"    {l}")

        passed = (res.returncode == 0) and ("[FAIL]" not in output)
        if not passed:
            all_passed = False
            results.append((name, "FAIL", duration))
            print(f"    --> [FAIL] Exit code: {res.returncode}")
        else:
            results.append((name, "PASS", duration))
            print(f"    --> [PASS] ({duration:.2f}s)")

    print("\n" + "=" * 80)
    print("SUITE EXECUTION SUMMARY")
    print("=" * 80)
    for name, status, duration in results:
        indicator = "[PASS]" if status == "PASS" else "[FAIL]"
        print(f"  {indicator:<8} {name:<45} ({duration:.2f}s)")

    total_time = time.time() - total_start
    print("-" * 80)
    if all_passed:
        print(f"OVERALL RESULT: ALL {len(GATES)} GATES PASSED (Total time: {total_time:.2f}s)")
        print("=" * 80)
        sys.exit(0)
    else:
        print(f"OVERALL RESULT: VERIFICATION FAILED (Total time: {total_time:.2f}s)")
        print("=" * 80)
        sys.exit(1)

if __name__ == "__main__":
    main()

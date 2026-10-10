#!/usr/bin/env python3
"""
tools/run_tests.py
==================
RollFor Unified Test & Verification Suite Runner.
Modeled after HolyPriest unified verification runner.

Executes all core static analysis, syntax audits, and native runtime gates:
1. tools/check_lua50_syntax.py   (Native Lua 5.0.3 bytecode compiler check)

Returns exit code 0 if all checks pass, 1 if any check fails.
"""

import os
import subprocess
import sys
import time

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

CHECKS = [
    ("Native Lua 5.0.3 Compiler (check_lua50_syntax.py)", [sys.executable, os.path.join(SCRIPT_DIR, "check_lua50_syntax.py")]),
]

def main():
    print("=" * 80)
    print("ROLLFOR AUTOMATED VERIFICATION SUITE")
    print("=" * 80)
    
    total_start = time.time()
    all_passed = True
    results = []

    for name, cmd in CHECKS:
        print(f"\n>>> Running {name}...")
        start_t = time.time()
        res = subprocess.run(cmd, cwd=ADDON_ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", check=False)
        duration = time.time() - start_t
        
        output = (res.stdout or "") + (res.stderr or "")
        lines = [l for l in output.strip().splitlines() if l.strip()]
        for l in lines[-6:]:
            print(f"    {l}")
            
        passed = (res.returncode == 0)
        if not passed:
            all_passed = False
            results.append((name, "FAIL", duration))
            print(f"    --> [FAIL] Exit code: {res.returncode}")
        else:
            results.append((name, "PASS", duration))
            print(f"    --> [PASS] ({duration:.2f}s)")

    total_duration = time.time() - total_start
    print("\n" + "=" * 80)
    print("SUITE EXECUTION SUMMARY")
    print("=" * 80)
    for name, status, d in results:
        badge = "[PASS]" if status == "PASS" else "[FAIL]"
        print(f"  {badge:7s}  {name:<50s} ({d:.2f}s)")
    print("-" * 80)
    if all_passed:
        print(f"OVERALL RESULT: ALL {len(CHECKS)} CHECKS PASSED (Total time: {total_duration:.2f}s)")
        print("=" * 80)
        sys.exit(0)
    else:
        print(f"OVERALL RESULT: SOME CHECKS FAILED (Total time: {total_duration:.2f}s)")
        print("=" * 80)
        sys.exit(1)

if __name__ == "__main__":
    main()

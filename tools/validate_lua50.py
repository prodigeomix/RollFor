#!/usr/bin/env python3
"""
Lua 5.0 and WoW 1.12 / Turtle WoW 1.18.1 Compatibility Validator
Scans .lua files for post-Lua 5.0 syntax and incompatible APIs.
"""

import sys
import os
import re

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BANNED_PATTERNS = [
    (r'(?<![A-Za-z0-9_])#\s*[A-Za-z0-9_\{\(\"\']', "Length operator '#' (Lua 5.1+). Use 'table.getn(t)', 'getn(t)', or 'string.len(s)'."),
    (r'(?<![A-Za-z0-9_])%\s*[A-Za-z0-9_\{\(\"\']', "Modulo operator '%' (Lua 5.1+). Use 'math.mod(a, b)' or 'mod(a, b)'."),
    (r'\bstring\.match\b', "'string.match' (Lua 5.1+). Use 'string.find' with return capture indexes."),
    (r'\bstring\.gmatch\b', "'string.gmatch' (Lua 5.1+). Use 'string.gfind'."),
    (r'\btable\.unpack\b', "'table.unpack' (Lua 5.1+). Use global 'unpack()'."),
    (r'\btable\.pack\b', "'table.pack' (Lua 5.1+). Construct a table with { n = arg.n, unpack(arg) }."),
    (r'\bselect\s*\(', "'select()' (Lua 5.1+). Index into 'arg' table directly."),
    (r'\bmath\.huge\b', "'math.huge' (Lua 5.1+). Use '1/0' or a large number (999999)."),
    (r'\bhooksecurefunc\b', "'hooksecurefunc' (WoW 2.0+). Use classic function detouring."),
    (r':HookScript\b', "':HookScript' (WoW 2.0+). Use standard 1.12 hook assignment."),
    (r'\bC_[A-Za-z0-9_]+\b', "Modern WoW API namespace 'C_*' (WoW 6.0+ / Retail). Use Vanilla globals."),
]

def strip_comments_and_strings(code):
    """
    Strips single line comments (-- ...) and string literals from Lua code
    to avoid false positives inside text.
    """
    lines = code.split('\n')
    cleaned_lines = []
    for line in lines:
        # Remove single line comments
        comment_idx = line.find('--')
        if comment_idx != -1:
            line = line[:comment_idx]
        # Replace string contents with empty quotes to preserve line structure
        line = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', line)
        line = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", line)
        cleaned_lines.append(line)
    return cleaned_lines

def validate_file(filepath):
    if not os.path.exists(filepath):
        print(f"Error: File '{filepath}' does not exist.")
        return False

    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    cleaned_lines = strip_comments_and_strings(content)
    violations = []

    for line_num, line in enumerate(cleaned_lines, start=1):
        for pattern, description in BANNED_PATTERNS:
            if re.search(pattern, line):
                original_line = content.split('\n')[line_num - 1].strip()
                violations.append((line_num, original_line, description))

    print(f"\nScanning: {filepath}")
    if violations:
        print(f"❌ Found {len(violations)} Lua 5.0 / WoW 1.12 compatibility issue(s):\n")
        for line_num, code_snippet, desc in violations:
            print(f"  Line {line_num}: {desc}")
            print(f"    Code: {code_snippet}\n")
        return False
    else:
        print("✅ No Lua 5.1+ compatibility violations detected!")
        return True

def scan_directory(dir_path):
    all_passed = True
    for root, _, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.lua'):
                full_path = os.path.join(root, file)
                if not validate_file(full_path):
                    all_passed = False
    return all_passed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python validate_lua50.py <file_or_directory_path>")
        sys.exit(1)

    target = sys.argv[1]
    if os.path.isdir(target):
        success = scan_directory(target)
    else:
        success = validate_file(target)

    sys.exit(0 if success else 1)

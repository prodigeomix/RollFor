#!/usr/bin/env bash
# Run RollFor tests from within the addon directory using Lua 5.1

set -o pipefail

# Resolve script directory (addon root)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Use lua5.1 from PATH (or specify full path)
LUA=${LUA:-lua5.1}

# Set up paths for the addon structure:
# - src/*.lua (main modules)
# - src/vanilla/*.lua (Lua 5.0 backports)
# - src/bcc/*.lua (Lua 5.1 compat helpers)
# - libs/vanilla/LibStub/*.lua (Lua 5.0 LibStub)
# - test/*.lua (test files)
# - test/mocks/*.lua (mock modules)
# - test/fixtures/*.lua (test data)
export LUA_PATH="./?.lua;./test/?.lua;./test/mocks/?.lua;./test/fixtures/?.lua;./src/?.lua;./src/vanilla/?.lua;./src/bcc/?.lua;./libs/vanilla/LibStub/?.lua;./libs/bcc/LibStub/?.lua;${LUA_PATH}"

echo "Running RollFor tests..."
echo "Lua: $LUA"
echo "Path: $LUA_PATH"
echo ""

find test -name "*_test.lua" | sort | while read -r file; do
  echo "Testing $file..."
  $LUA "$file" -o text -v -T Spec -m should 2>&1 || exit 1
done

echo ""
echo "All tests passed."

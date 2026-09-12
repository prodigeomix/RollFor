# Test harness - only runs tests compatible with standalone addon
# Integration tests requiring full mock environment are excluded

# Run all tests
for f in test/*_test.lua; do
  if [ -f "$f" ]; then
    echo "Testing $f..."
    ${LUA:-lua5.1} "$f" -o text -v -T Spec -m should 2>&1 || exit 1
  fi
done

# Test harness - only runs tests compatible with standalone addon
# Integration tests requiring full mock environment are excluded

# Run all tests that work
for f in test/SRPlusFormat_test.lua test/SoftResRealData_test.lua test/SoftResDataTransformer_test.lua test/AutoLootSpec_test.lua test/DroppedLootAnnounce_test.lua test/SoftRes_test.lua test/ItemUtils_test.lua test/LootList_test.lua test/modules_test.lua test/GroupRosterApi_test.lua test/test_utils_test.lua; do
  if [ -f "$f" ]; then
    echo "Testing $f..."
    ${LUA:-lua5.1} "$f" -o text -v -T Spec -m should 2>&1 || exit 1
  fi
done

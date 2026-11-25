#!/usr/bin/env bash
set -u

SLOX_BIN="${SLOX_BIN:-slox}"

TESTS=(
  test_expr.lox
  test_scanner.lox
  test_parser.lox
  test_pass1.lox
  test_assembler.lox
  test_directives.lox
  test_fixpoint.lox
  test_assert.lox
  test_textconv.lox
  test_macros.lox
  test_conditionals.lox
  test_diagnostics.lox
  test_cairo_sprite_editor.lox
  test_writeprg.lox
  test_d64writer.lox
)

passed=0
failed=0

echo "Running c64 assembler tests..."
echo "=============================="

for test_file in "${TESTS[@]}"; do
  expected_tmp=$(mktemp)
  actual_tmp=$(mktemp)

  grep '// expect:' "$test_file" | sed 's/.*\/\/ expect: //' > "$expected_tmp"
  "$SLOX_BIN" "$test_file" > "$actual_tmp" 2>&1
  grep -vE '^\[.*:[0-9]+\] in .+' "$actual_tmp" > "${actual_tmp}.filtered"

  if diff -u "$expected_tmp" "${actual_tmp}.filtered" > /dev/null; then
    echo "  [PASS] $test_file"
    ((passed++))
  else
    echo "  [FAIL] $test_file"
    diff -y -W 90 "$expected_tmp" "${actual_tmp}.filtered" | sed 's/^/    /'
    ((failed++))
  fi

  rm -f "$expected_tmp" "$actual_tmp" "${actual_tmp}.filtered"
done

echo "=============================="
echo "Passed: $passed"
echo "Failed: $failed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi

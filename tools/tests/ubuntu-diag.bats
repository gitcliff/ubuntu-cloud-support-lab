#!/usr/bin/env bats
# Tests for tools/ubuntu-diag.sh. Run with: bats tools/tests

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../ubuntu-diag.sh"
  OUT="$(mktemp -d)"
}

teardown() {
  rm -rf "$OUT"
}

@test "-h prints usage and exits 0" {
  run "$SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "-V prints a version number" {
  run "$SCRIPT" -V
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "unknown option exits 2" {
  run "$SCRIPT" -Z
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option"* ]]
}

@test "-o with missing argument exits 2" {
  run "$SCRIPT" -o
  [ "$status" -eq 2 ]
}

@test "non-existent output directory exits 1" {
  run "$SCRIPT" -q -o "$OUT/does-not-exist"
  [ "$status" -eq 1 ]
}

@test "creates a tarball by default" {
  run "$SCRIPT" -q -o "$OUT"
  [ "$status" -eq 0 ]
  [[ "$output" == *.tar.gz ]]
  [ -f "$output" ]
  tar -tzf "$output" | grep -q "summary.txt"
}

@test "-n leaves a directory containing every section" {
  run "$SCRIPT" -q -n -o "$OUT"
  [ "$status" -eq 0 ]
  [ -d "$output" ]
  for s in system linux networking containers storage virtualization; do
    [ -d "$output/$s" ]
  done
  [ -f "$output/summary.txt" ]
}

@test "missing commands are recorded as SKIPPED, not failures" {
  source "$SCRIPT"
  REPORT_DIR="$OUT/r"
  mkdir -p "$REPORT_DIR"
  collect test missing definitely-not-a-real-command-xyz
  grep -q "SKIPPED" "$REPORT_DIR/test/missing.txt"
  grep -q "test/missing: skipped" "$REPORT_DIR/summary.txt"
}

@test "a failing command records its exit code" {
  source "$SCRIPT"
  REPORT_DIR="$OUT/r"
  mkdir -p "$REPORT_DIR"
  collect test fails false
  grep -q "test/fails: rc=1" "$REPORT_DIR/summary.txt"
}

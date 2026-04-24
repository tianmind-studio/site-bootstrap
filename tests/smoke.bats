#!/usr/bin/env bats
#
# Smoke tests for the site-bootstrap CLI. These don't touch a real VPS or
# Cloudflare — they exercise argument parsing, help text, YAML reading, and
# --dry-run paths. The point is catching regressions in the dispatcher and
# the helper library, not end-to-end coverage.

setup() {
  SB_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SB_BIN="$SB_ROOT/bin/site-bootstrap"
  TMP="$(mktemp -d)"
  cd "$TMP"
}

teardown() {
  [[ -n "${TMP:-}" && -d "${TMP:-}" ]] && rm -rf "$TMP"
}

# ---------------------------------------------------------------------------
# Top-level CLI
# ---------------------------------------------------------------------------

@test "version prints a semver-ish string" {
  run "$SB_BIN" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ site-bootstrap[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "--version alias works" {
  run "$SB_BIN" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "help exits 0 and mentions every command" {
  run "$SB_BIN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"new"*         ]]
  [[ "$output" == *"deploy"*      ]]
  [[ "$output" == *"dns"*         ]]
  [[ "$output" == *"cert"*        ]]
  [[ "$output" == *"rollback"*    ]]
  [[ "$output" == *"doctor"*      ]]
  [[ "$output" == *"--dry-run"*   ]]
}

@test "unknown command exits non-zero and suggests help" {
  run "$SB_BIN" nonsense-command
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown command"* ]]
}

# ---------------------------------------------------------------------------
# doctor — should work without a site.yaml and without credentials.
# ---------------------------------------------------------------------------

@test "doctor runs in an empty directory without crashing" {
  run "$SB_BIN" doctor
  # exit 0 or 1 (exit 1 when local tools missing); must not segfault / syntax
  # error. It MUST reach the 'Cloudflare credentials' stage.
  [[ "$output" == *"Local tools"* ]]
  [[ "$output" == *"Cloudflare credentials"* ]]
}

@test "doctor mentions site.yaml when missing" {
  run "$SB_BIN" doctor
  [[ "$output" == *"site.yaml"* ]]
}

# ---------------------------------------------------------------------------
# deploy — must refuse to run without config, cleanly.
# ---------------------------------------------------------------------------

@test "deploy in an empty dir fails with a clear error" {
  run "$SB_BIN" deploy
  [ "$status" -ne 0 ]
  [[ "$output" == *"site.yaml"* ]]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"missing"* ]]
}

# ---------------------------------------------------------------------------
# YAML reader edge cases via the public CLI surface.
# ---------------------------------------------------------------------------

@test "deploy reads a minimal site.yaml and advances past config loading" {
  cat > site.yaml <<'EOF'
name: smoke-test
domain: smoke.example.com
server: does-not-exist-alias
deploy:
  type: static
  source: .
dns:
  provider: cloudflare
  proxied: false
ssl:
  provider: letsencrypt
EOF
  # Put something at ./ so source=. doesn't trigger the "source missing" error.
  echo "<html></html>" > index.html

  # --dry-run: no network, no ssh, no apt. Should progress through
  # the pipeline printing intended actions.
  run "$SB_BIN" --dry-run deploy
  [[ "$output" == *"smoke-test"* ]] || [[ "$output" == *"smoke.example.com"* ]]
}

@test "deploy fails explicitly when deploy.source points at a missing dir" {
  cat > site.yaml <<'EOF'
name: smoke
domain: smoke.example.com
server: does-not-exist-alias
deploy:
  type: static
  source: dist
ssl:
  provider: letsencrypt
dns:
  provider: cloudflare
EOF
  # No ./dist exists.
  run "$SB_BIN" deploy
  [ "$status" -ne 0 ]
  # The user-visible message should name the missing directory.
  [[ "$output" == *"dist"* ]]
  [[ "$output" == *"does not exist"* ]] || [[ "$output" == *"missing"* ]]
}

# ---------------------------------------------------------------------------
# dns subcommand dispatch
# ---------------------------------------------------------------------------

@test "dns with no args prints help, not an error" {
  run "$SB_BIN" dns help
  [ "$status" -eq 0 ]
  [[ "$output" == *"dns"* ]]
  [[ "$output" == *"add"* ]]
}

@test "dns add without required args fails cleanly" {
  run "$SB_BIN" dns add
  [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# Global flag plumbing
# ---------------------------------------------------------------------------

@test "--config flag is picked up by deploy" {
  mkdir somewhere-else
  cat > somewhere-else/custom.yaml <<'EOF'
name: from-custom
domain: custom.example.com
server: x
deploy:
  type: static
  source: .
dns:
  provider: cloudflare
ssl:
  provider: letsencrypt
EOF
  echo "<html></html>" > index.html
  run "$SB_BIN" --config somewhere-else/custom.yaml --dry-run deploy
  [[ "$output" == *"from-custom"* ]] || [[ "$output" == *"custom.example.com"* ]]
}

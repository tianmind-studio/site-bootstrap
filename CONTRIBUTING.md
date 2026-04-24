# Contributing to site-bootstrap

Thanks for your interest. A few notes before you open a PR so we don't waste
each other's time.

## Bug reports

Please include, in this order:

1. Your OS and `bash --version`.
2. The exact command you ran, with `--verbose` if relevant.
3. The output — the full output, not a paraphrase.
4. The contents of your `site.yaml` (redact anything sensitive).

Bug reports without these take much longer to resolve. Reports with them
usually get a fix within a day or two.

## Feature requests

Open an issue first. Describe:

- The real-world scenario — what are you actually trying to deploy?
- What command line or `site.yaml` shape you would expect to work.
- Any alternatives you tried.

Feature creep is the leading cause of tools like this becoming unusable.
Proposals that would make site-bootstrap a general-purpose deployer
(**Kubernetes, blue-green, canary, multi-region**) will be politely declined.
See the "Not a good fit" section in [README.md](./README.md#适合--不适合--good--bad-fits).

## Pull requests

Before writing code for anything non-trivial:

1. Open an issue.
2. Agree on the shape of the solution.
3. Then write the PR.

For trivial fixes (typo, obviously missing `set -u` guard, broken
shellcheck), just send the PR.

### Code style

- **Bash only.** No Python, Node, Ruby.
- **Dependencies stay tight**: `bash`, `ssh`, `rsync`, `jq`, `curl`, `awk`, `sed`.
  If you need anything else, open an issue first.
- **Zero global state.** Every `sb_cmd_*` function must be safely callable
  more than once in the same shell.
- **`set -euo pipefail` is on.** Respect it. `|| true` is allowed only with a
  comment explaining why.
- **Idempotency.** Every command should be safe to re-run.
- **`--dry-run` support.** Any new action must go through `sb_run`.

### Testing locally

Minimum before requesting review:

```bash
shellcheck -x -e SC1091 bin/site-bootstrap lib/*.sh install.sh
bats tests/                     # install bats-core first (brew / apt)
./bin/site-bootstrap --help
./bin/site-bootstrap doctor
```

CI runs both `shellcheck` and `bats tests/` on every push — see
`.github/workflows/ci.yml`. If you add a new subcommand, add at least a help-
text assertion to `tests/smoke.bats`.

If you changed deploy logic, also run end-to-end against a throwaway VPS:

```bash
cd /tmp && ./bin/site-bootstrap new sb-smoke-test
cd sb-smoke-test && ./bin/site-bootstrap --dry-run deploy
```

### Commit messages

Use conventional commits: `feat(scope): ...`, `fix(scope): ...`, `docs: ...`,
`ci: ...`, `chore: ...`. Keep the summary line under ~72 characters. The body
can be as long as it needs to be — but should explain **why**, not restate
the diff.

## License

By submitting a PR you agree that your contribution is licensed under MIT
(same as the project).

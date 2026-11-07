# Contract: repository files and the submission listing

the `Gemfile.lock` platforms, `bin/run`'s storage, and what the pushed `main` must and must not hold (FR-015 to FR-019, FR-026 to FR-030; [DEC-01](../../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../../docs/design-analysis/design-decisions.md#dec-22), [DEC-27](../../../docs/design-analysis/design-decisions.md#dec-27), [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36), [DEC-38](../../../docs/design-analysis/design-decisions.md#dec-38)).

## No `.gitattributes`

The repository holds no `.gitattributes` file (`test ! -e .gitattributes`, C-02) and no attribute that changes how a file is checked out. A Windows checkout made with `core.autocrlf=true` therefore gives every Ruby file, `bin/run` included, CRLF, and `bundle exec rubocop` reports `no offenses detected` in it (C-43), because RuboCop's default `Layout/EndOfLine` (`native`) wants CRLF on Windows. RuboCop's settings are not changed (DEC-36).

## `Gemfile.lock`

- The `PLATFORMS` section lists `aarch64-linux`, `arm64-darwin`, `ruby`, `x64-mingw-ucrt`, `x86_64-darwin` and `x86_64-linux` (plan item 2), added with:

  ```
  bundle lock --add-platform ruby x64-mingw-ucrt x86_64-linux aarch64-linux x86_64-darwin arm64-darwin
  ```

- The `GEM` specs (names and versions) are the ones `001-domain` locked: `git diff Gemfile.lock` after the command shows changes only in `PLATFORMS`, and, where Bundler lists a gem once per platform, only new platform lines for the same version.
- The `Gemfile` names only `csv`, `bigdecimal`, `logger`, `rspec`, `simplecov`, `rubocop` and `rubocop-rspec` (FR-016; checked, not changed).

## `bin/run`

- Git mode `100755` (`git ls-files -s bin/run`); fixed, if needed, with `git update-index --chmod=+x bin/run` (plan item 14).
- First line exactly `#!/usr/bin/env ruby`.
- `bundle exec rubocop bin/run` reports no offence. If it reports one, the only change this spec makes is `# frozen_string_literal: true` on line 2; any other offence is a cross-spec finding against `002-file-runner`, fixed there test-first.
- Stored with LF (`git ls-files --eol bin/run` shows `i/lf`). The working copy follows the machine's Git setting: LF on Linux and macOS, CRLF in a Windows checkout with `core.autocrlf=true` (`w/crlf`), where it is started as `ruby bin/run` (also in Docker: the image's command is `ruby bin/run`), which ignores the line ending of the `#!` line.

## Every text file

`git ls-files --eol` shows no `i/crlf` (plan item 13).

## The pushed `main`: must be tracked (`git ls-files`)

`README.md`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.gitignore`, `.rspec`, `.rubocop.yml`, `Dockerfile`, `.github/workflows/ci.yml`, `bin/run`, `lib/domain/`, `lib/application/`, `lib/infrastructure/`, `spec/` (with `spec/fixtures/sample/mable_account_balances.csv` and `spec/fixtures/sample/mable_transactions.csv`), `data/mable_account_balances.csv`, `data/mable_transactions.csv`, `docs/`, `specs/` (US6 scenario 1).

## The pushed `main`: must not be tracked

Any path under `output/` or `coverage/` (FR-027).

## Copies of the challenge files

These blob IDs must be equal, pair by pair (`git rev-parse HEAD:<path>`; plan item 13):

| Challenge file | Copy in `data/` | Copy in `spec/fixtures/sample/` |
|---|---|---|
| `docs/challenge/mable_account_balances.csv` | `data/mable_account_balances.csv` | `spec/fixtures/sample/mable_account_balances.csv` |
| `docs/challenge/mable_transactions.csv` | `data/mable_transactions.csv` | `spec/fixtures/sample/mable_transactions.csv` |

`docs/challenge/` has no difference from the commit that added it (FR-028).

## What this spec adds, and nothing more (FR-030, SC-007)

Compared with the tip of `002-file-runner`'s implementation, this spec's commits touch only `README.md`, `.github/workflows/ci.yml`, `Dockerfile`, `Gemfile.lock` (platforms), `bin/run` (its Git mode and, if missing or different, its first line `#!/usr/bin/env ruby`; and, only if RuboCop then reports it, `# frozen_string_literal: true` on line 2; nothing else; spec item 16) and documents under `docs/` and `specs/`. No file under `lib/`, `spec/` or `data/` changes.

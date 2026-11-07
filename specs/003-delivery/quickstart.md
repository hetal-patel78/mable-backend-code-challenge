# Quickstart: the checks for 003-delivery

Phase 1 of the [plan](plan.md). This spec is checked by these commands, not by RSpec specs (brief rule 4; FR-030). Each check is written down before the file it checks, run once to see it fail, and run again once the file is in place. Each result is recorded in the run report, `docs/spec-kit/implementation-run-report.md` (Part 2 section), with the platform, date, commit and evidence. A check that cannot run on the machine at hand is recorded as "left for the developer", never as passed (FR-025; C-28).

## Prerequisites

- `001-domain` and `002-file-runner` are implemented: `bundle exec rspec` passes in random order and `bundle exec rubocop` reports no offences.
- Git and Bash (Git Bash on Windows) for the repository checks; Ruby at the version in `.ruby-version` for the Ruby checks; Docker for the Docker checks; Windows with RubyInstaller at that version and PowerShell for the Windows checks (any version: the program's output is captured through `cmd /c`, so the files hold the program's own bytes and PowerShell's redirection changes nothing); the GitHub CLI `gh` (or the Actions page) for the CI checks.
- The Docker commands (C-17 to C-25, C-27 and the Phase 4 fallback in tasks.md) run only from a Linux, macOS or WSL shell, with `$CHECKS` and `$CLEAN` on that shell's own filesystem. Git Bash is not used for them: with path conversion on it rewrites arguments that start with `/` (`-w /src`, the container side of `-v`), and with it off the host side of `-v` stays a POSIX path such as `/tmp/tmp.XXXX`, which Docker Desktop cannot map to the Windows folder, so the mounts would be empty (plan, Decided in the run, item 17). C-26 and C-41 are PowerShell commands that use Windows paths and are not affected.
- Scratch files go in a temporary folder outside the repository, called `$CHECKS` below (`CHECKS=$(mktemp -d)`, made in the shell that runs the check). `$REPO` is the working repository, set in each shell that uses it: in Bash `REPO=<path of the working repository>` (inside it, `REPO=$(git rev-parse --show-toplevel)`); in PowerShell `$REPO = '<Windows path of the working repository>'` (the folder `git rev-parse --show-toplevel` prints there, as a Windows path). `$CLEAN` is a clean checkout.
- The Windows checks (C-13 to C-16, C-26, C-41) run in PowerShell and need their own scratch folder, because a Git Bash path such as `/tmp/tmp.XXXX` cannot be opened there: `$env:CHECKS = (New-Item -ItemType Directory (Join-Path $env:TEMP "checks-003")).FullName`. Copy `report.txt`, `usage.txt` and `final.csv` from the Bash `$CHECKS` into that folder before C-13 (`final.csv` keeps its LF line endings). Ruby on Windows writes the console streams in text mode, so CRLF in `wout.txt`, `herr.txt` and `dout.txt` is expected and is not a defect in 002; those three are compared with CRLF changed to LF, and only the output CSV is compared byte for byte (AC-08.3, page 10 pick 17).

## Expected texts

- **The sample report**: the block "The sample report" in [spec.md](spec.md#conventions-used-in-the-scenarios) (AC-08.1 with `2026-11-07_143005` replaced by `<run time>`). Save it as `$CHECKS/report.txt`.
- **The sample output file**: the block "The sample output file" in [spec.md](spec.md#conventions-used-in-the-scenarios). Save it as `$CHECKS/final.csv`, with LF line endings and a final LF.
- **The usage message**: the two lines of AC-09.2, saved as `$CHECKS/usage.txt`.
- **The info log**: the six lines of AC-09.5.

To compare a run with the report: take `<run time>` from the name of the file the run created (`final_balances_<run time>.csv`), replace `<run time>` in `report.txt` with it, and `diff` the result with the run's standard output. `diff` must print nothing.

## Repository files (Foundational)

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-01 | `bin/run` is executable, starts with the Ruby line and is LF; every text file is stored LF | `git ls-files -s bin/run`; `git show :bin/run \| head -1`; `git ls-files --eol \| grep 'i/crlf'` | `100755`; `#!/usr/bin/env ruby` (if it differs, T006 sets it, spec item 16); the grep prints nothing | FR-018; DEC-22, DEC-04 |
| C-02 | `.gitattributes` is the one line | `od -c .gitattributes` | exactly `bin/run text eol=lf\n` | FR-018 |
| C-03 | `Gemfile.lock` platforms, versions unchanged | `git show :Gemfile.lock \| sed -n '/^PLATFORMS/,/^$/p'`; `git diff <001 lock commit> -- Gemfile.lock` | the six platforms of [repository-files.md](contracts/repository-files.md#gemfilelock); the diff touches only platforms | FR-017; DEC-01 |
| C-04 | One Ruby version in `.ruby-version` and the Dockerfile | `test "$(head -1 Dockerfile \| tr -d '\r')" = "FROM ruby:$(tr -d '\r' < .ruby-version)"` (or `...-bookworm`, plan item 7) | exit status 0; `.ruby-version` is the latest 3.4.x release | FR-015, SC-005; DEC-01 |
| C-05 | Only the named gems, and the four tools only for development | `grep -nE "^\s*(gem\|group\|end)\b" Gemfile`; read the output against 001 FR-037 | `csv`, `bigdecimal`, `logger` outside any `group` block; `rspec`, `simplecov`, `rubocop`, `rubocop-rspec` only inside a `group :development` / `:test` block; no other gem | FR-016; NFR-04; DEC-01 |
| C-40 | Input files are read only through Ruby's CSV library (design review) | `grep -rn -e 'File.read' -e 'IO.read' -e 'readlines' -e 'each_line' lib/`; read the readers in `lib/infrastructure` | the grep finds no reading of an input file; the readers open the files as `bom\|utf-8` through CSV (`002` FR-001), so CRLF, a missing final newline and a byte-order mark give the same result (the last proved by `002`'s fixture test) | FR-019; NFR-04; DEC-04, DEC-22 |

## CI (User Story 4)

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-06 | The workflow holds what it must and nothing it must not | read `.github/workflows/ci.yml` against [ci-workflow.md](contracts/ci-workflow.md); `grep -nE "matrix\|ruby-version\|bundler-cache\|continue-on-error\|pull_request\|coverage" .github/workflows/ci.yml` | every "must hold" row present; the grep prints nothing; no step ends with `\|\| true` | FR-020, FR-021; DEC-36; US4-2, US4-3 |
| C-07 | A push runs CI and it passes | `gh run list --commit $(git rev-parse HEAD) --limit 1`; `gh run view <id> --log` | one run, status `completed`, conclusion `success`; the log shows a frozen install, `0 failures`, RuboCop `no offenses detected` | FR-020, SC-002; DEC-36; US4-1 |

## Ruby on Linux or macOS, from a clean checkout (User Story 1)

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-08 | Make a clean checkout | `CLEAN=$CHECKS/clean; git clone --branch main <origin url> "$CLEAN"; cd "$CLEAN"` | a new folder with no `output/`, `coverage/` or `vendor/` | spec item 2 |
| C-09 | The gems install at the locked versions | `BUNDLE_FROZEN=true bundle install; git status --porcelain; echo $?` (in a container, `git config --global --add safe.directory /src` first, so git does not refuse the mounted checkout) | exit status 0; `git status` prints nothing and exits 0 (a refusal with exit 128 is a failure) | US1-1; FR-017; DEC-01 |
| C-10 | The sample files with no arguments | `bin/run >$CHECKS/out.txt 2>$CHECKS/err.txt; echo $?`; compare as above; `cmp output/final_balances_*.csv $CHECKS/final.csv` | `0`; the report matches; `err.txt` is empty; `cmp` prints nothing | US1-2; AC-08.1; DEC-22, DEC-35, DEC-27 |
| C-11 | From another folder | `rm -r output; cd docs; ../bin/run >$CHECKS/out2.txt 2>$CHECKS/err2.txt; echo $?; cd ..` | `0`; the report with last line `Output file: ../output/final_balances_<run time>.csv`; `err2.txt` empty; the file is in `$CLEAN/output/` | US1-3; AC-08.4; DEC-22, DEC-26 |
| C-12 | Tests and style checker | `bundle exec rspec; echo $?; bundle exec rubocop; echo $?` | `0 failures`, `Randomized with seed`, `0`; SimpleCov's `Line Coverage:` line and a `coverage/` folder; `no offenses detected`, `0` | US1-4; DEC-34, DEC-36 |

## Windows (User Story 2), PowerShell

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-13 | The sample files on Windows | `git clone -c core.autocrlf=true --branch main <origin url> $env:CHECKS\win; cd $env:CHECKS\win; $env:BUNDLE_FROZEN='true'; bundle install; git status --porcelain; cmd /c "ruby bin/run > ..\wout.txt 2> ..\werr.txt"; $LASTEXITCODE` | install succeeds, `git status` prints nothing; `0`; `wout.txt`, read with CRLF changed to LF (``(Get-Content -Raw ..\wout.txt).Replace(([string][char]13+[string][char]10), [string][char]10)``), equals `report.txt` (with `<run time>` filled in) line by line, with `/` in `Output file: output/final_balances_<run time>.csv`; `werr.txt` is 0 bytes; `[IO.File]::ReadAllBytes(<output file>)` equals `final.csv` byte for byte (LF, not CRLF) | US2-1; FR-025(b); spec item 15; DEC-22, DEC-35, DEC-37; page 10 pick 17 |
| C-14 | Wrong arguments on Windows | `cmd /c "ruby bin/run -h > ..\hout.txt 2> ..\herr.txt"; $LASTEXITCODE` | `1`; `hout.txt` is 0 bytes; `herr.txt`, read with CRLF changed to LF, equals `usage.txt` line by line | US2-2; AC-09.2; DEC-22, DEC-25 |
| C-15 | From another folder on Windows | `Remove-Item -Recurse output; cd docs; cmd /c "ruby ..\bin\run > ..\..\dout.txt"; $LASTEXITCODE; cd ..` | `0`; `dout.txt`, read with CRLF changed to LF, equals `report.txt` line by line except its last line, which is `Output file: ../output/final_balances_<run time>.csv` | edge case; AC-08.4; DEC-22, DEC-26 |
| C-16 | Windows line endings in the input | `git ls-files --eol data/` | `w/crlf` for both files, and C-13 still gave the sample report | US2-3; DEC-04 |

## Docker (User Story 3), in its own fresh clean checkout

These checks run in a fresh clean checkout made only for them, with no earlier run in it (so no `output/` or `coverage/` from C-10 to C-12 is copied into the image): `git clone --branch main <origin url> $CHECKS/docker; cd $CHECKS/docker` (as T025 in tasks.md). Below, `$CLEAN` means this checkout.

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-17 | The image builds | `docker build -t mable-transfers .; echo $?` | `0`; the build log shows `bundle install` using the locked versions, with no "lockfile" change error | US3-1; FR-022; DEC-01, DEC-36 |
| C-18 | Time-zone data in the image | `docker run --rm mable-transfers test -f /usr/share/zoneinfo/Australia/Sydney; echo $?` | `0` (otherwise plan item 7) | US3-2; FR-022; DEC-37 |
| C-19 | Sample files, `output` mounted, `TZ` set | `mkdir -p output; docker run --rm -e TZ=Australia/Sydney -v "$(pwd)/output:/app/output" mable-transfers >$CHECKS/dout.txt 2>$CHECKS/derr.txt; echo $?` | `0`; the report matches; `derr.txt` empty; the file is in this checkout's `output/` folder, equal to `final.csv`; `<run time>` is Sydney's local time at the run (`TZ=Australia/Sydney date`) | US3-2; FR-023; DEC-27, DEC-36, DEC-37 |
| C-20 | Tests in the container | `docker run --rm mable-transfers bundle exec rspec; echo $?` | `0 failures`, `Randomized with seed`, `0` | US3-3; FR-023; DEC-34, DEC-36 |
| C-21 | Log level and exit status pass through | `docker run --rm -e LOG_LEVEL=info mable-transfers >$CHECKS/o.txt 2>$CHECKS/e.txt; echo $?`; `docker run --rm mable-transfers bin/run -h >$CHECKS/o2.txt 2>$CHECKS/e2.txt; echo $?` | `0`, `$CHECKS/o.txt` the report, `$CHECKS/e.txt` the six AC-09.5 lines (timestamps and pid aside); `1`, `$CHECKS/o2.txt` empty, `$CHECKS/e2.txt` the usage message | US3-4; AC-09.5, AC-09.2; DEC-25, DEC-28 |
| C-22 | No `TZ` | `docker run --rm -v "$(pwd)/output:/app/output" mable-transfers` | exit 0; the file name carries the UTC time (`date -u`) | edge case; DEC-37 |
| C-23 | No mount | `rm -r output; docker run --rm mable-transfers; ls output` | exit 0; the report on standard output; `ls` finds no `output/` on the host | edge case; DEC-37 |
| C-24 | An existing file of the same name in the mount | `mkdir -p output; echo keep > output/existing.csv; docker run --rm -v "$(pwd)/output:/app/output" mable-transfers bin/run data/mable_account_balances.csv data/mable_transactions.csv output/existing.csv; echo $?; cat output/existing.csv` | standard output (nothing); standard error `Error: output file already exists: output/existing.csv. Delete it or give another output path.` then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)`; `1`; `keep` | edge case; AC-09.3; DEC-25, DEC-27 |
| C-25 | A reviewer's own files, mounted | `mkdir $CHECKS/mine; cp data/*.csv $CHECKS/mine/; docker run --rm -v "$CHECKS/mine:/app/mine" -v "$(pwd)/output:/app/output" mable-transfers bin/run mine/mable_account_balances.csv mine/mable_transactions.csv; echo $?` | `0`; the sample report (last line `Output file: output/final_balances_<run time>.csv`); the copies are scratch files, never committed | edge case; DEC-22, DEC-37 |
| C-26 | An image built from a Windows checkout starts `bin/run` | in a fresh Windows clone made after the Dockerfile is committed, with no `output/` folder (`git clone -c core.autocrlf=true --branch main <origin url> $env:CHECKS\win2; cd $env:CHECKS\win2`): `git ls-files --eol bin/run` then `docker build -t mable-transfers-win .; docker run --rm mable-transfers-win; $LASTEXITCODE; docker rmi mable-transfers-win` | `w/lf` for `bin/run`; `0` and the sample report | edge case; FR-018; DEC-22 |
| C-41 | The README's PowerShell Docker command, as written | in PowerShell on Windows with Docker Desktop, in the same fresh `win2` clone as C-26 (no `output/` folder before this check), immediately after `docker build -t mable-transfers .`: run the README's command exactly as written, `docker run --rm -e TZ=Australia/Sydney -v "${PWD}/output:/app/output" mable-transfers`, with standard output and standard error captured through `cmd /c` to `dockerout.txt` and `dockererr.txt`; then `$LASTEXITCODE` | `0`; `dockerout.txt` equals `report.txt` (with `<run time>` filled in); `dockererr.txt` is 0 bytes; the sample output file is in the clone's `output/` folder and equals `final.csv` byte for byte; if it cannot run, recorded under C-28 as left for the developer | US5-2; FR-005; SC-003; DEC-37 |
| C-27 | Docker on a Linux host writes as root | on a Linux host, after C-19: `ls -l output/` | `output/` was created by the host user in C-19 (`mkdir -p output`), so the folder is the host user's and C-23 and C-24 can remove and write in it; the file the container wrote belongs to root, as the README says (on Docker Desktop the owner is the host user; record which was seen) | edge case; spec Clarifications; DEC-36, DEC-37 |
| C-42 | The Dockerfile holds exactly the six instructions and nothing else | at `$REPO` and on each clean checkout: `grep -cvE '^[[:space:]]*(#.*)?$' Dockerfile`; `grep -nE '^(USER\|ENTRYPOINT\|EXPOSE\|ADD)\|apt-get\|gem install' Dockerfile`; `test ! -e .dockerignore; echo $?`; and read `Dockerfile` against [contracts/dockerfile.md](contracts/dockerfile.md) line by line | `6`; the second command prints nothing; `0`; the instructions are `FROM`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN bundle install`, `CMD ["bin/run"]`, in that order | FR-022, FR-024; DEC-36 |

## Hand checks not run (all stories)

| ID | Check | Expected | Refs |
|---|---|---|---|
| C-28 | Every hand check (C-08 to C-12 on Linux or macOS or in the Phase 4 fallback container, C-13 to C-16 and C-41 on Windows, C-17 to C-27 with Docker) that could not run on the machine at hand | listed in the run report as left for the developer, with the reason (no Ruby 3.4 for Windows, no Docker, no Linux host, no Linux or macOS Ruby and no Docker); none marked passed | FR-025, SC-001; edge case |

## README (User Story 5)

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-29 | Every README command works as written | each command in the README equals one already run in C-09 to C-26 and C-41 (C-41 runs the PowerShell Docker command); plain `bundle install`, exactly as the README gives it, is run once on a fresh clean checkout and gives exit status 0 with `git status --porcelain` printing nothing (Gemfile.lock unchanged); the 2-argument form `bin/run b.csv t.csv` and the 3-argument form `bin/run b.csv t.csv out/day1.csv` are each run on the clean checkout with copies of the sample files | each gives the outcome the README says; for `bin/run b.csv t.csv`: standard output the sample report with last line `Output file: output/final_balances_<run time>.csv`, standard error (nothing), exit status `0`; for `bin/run b.csv t.csv out/day1.csv`: standard output the sample report with last line `Output file: out/day1.csv`, standard error (nothing), exit status `0`, and `cmp out/day1.csv $CHECKS/final.csv` prints nothing | US5-2; AC-09.1, AC-08.1, AC-08.3; FR-001 to FR-005; DEC-37 |
| C-30 | Exact texts match page 2 | `diff` the README's sample report block with AC-08.1, and its usage block with AC-09.2 | `diff` prints nothing | US5-3; FR-002, FR-003; DEC-22, DEC-25, DEC-26 |
| C-31 | The README check | read the README against R-01 to R-14 in [readme.md](contracts/readme.md#the-readme-check-c-31) | 14 of 14 present, in order | US5-1; SC-003; DEC-37 |
| C-32 | Every relative link resolves | `grep -oE '\]\([^)#]+' README.md \| sed 's/](//' \| grep -v '^http' \| while read p; do test -e "$p" \|\| echo "missing $p"; done` | prints nothing; links to sections open on GitHub | US5-5; DEC-37, DEC-38 |
| C-33 | The coverage figure is current | `bundle exec rspec \| grep "Line Coverage"` on the clean checkout of the submitted commit, and the same line in the CI log of that commit | both equal the README's line | US5-4; FR-012, SC-004; DEC-36 |

## The submission (User Story 6), on `main` after the push

| ID | Check | Command | Expected | Refs |
|---|---|---|---|---|
| C-34 | This spec adds no spec, class or test-data file | `git diff --stat <002 implementation tip> main -- lib spec data` | prints nothing | FR-030, SC-007; brief rule 4 |
| C-35 | What the repository holds | `git ls-files` | every path in [repository-files.md](contracts/repository-files.md#the-pushed-main-must-be-tracked-git-ls-files) | US6-1; FR-026; DEC-38, DEC-01 |
| C-36 | Nothing generated | `git ls-files output coverage`; on the clean checkout after C-10 and C-12: `git status --porcelain` | both print nothing | US6-2; FR-027, SC-006; DEC-27, DEC-36 |
| C-37 | The challenge files unchanged, and the copies equal | `git diff --exit-code $(git log --diff-filter=A --format=%H -- docs/challenge/MABLE_BACK_END_CODE_TEST.md \| tail -1) HEAD -- docs/challenge/`; `git rev-parse HEAD:<path>` for each pair in [repository-files.md](contracts/repository-files.md#copies-of-the-challenge-files) | exit status 0; equal blob IDs pair by pair | US6-3; FR-028, SC-006; DEC-22 |
| C-38 | CI is green on the latest `main` commit | `gh run list --branch main --limit 1` | conclusion `success`, for the commit `git rev-parse origin/main` | US6-4; FR-029, SC-002; DEC-36 |
| C-39 | Making the repository public is left to the developer | the run report's "left for the developer" list | it names making the repository public, or sharing it with the reviewer, at submission time | US6-4; FR-029; DEC-38 |

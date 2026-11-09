# Contract: `README.md`

What the repository root `README.md` must hold, in order, and the README check that reads it (FR-001 to FR-014; [DEC-37](../../../docs/design-analysis/design-decisions.md#dec-37), [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36)). Headings are plan item 9. Exact texts are copied from [page 2](../../../docs/solution-design/02-functional-requirements.md) and [`design-decisions.md`](../../../docs/design-analysis/design-decisions.md), never retyped.

## Sections, in order

The README opens with the title `# Mable Back End Code Challenge` and at most two sentences on what the program does (load one company's opening balances from a CSV file, apply one day's transfers from a second, never letting a balance go below $0). Then:

### 1. `## Build, test and run` (FR-001 to FR-005)

1. `### With Ruby 3.4` (FR-001, FR-002, FR-003; [DEC-01](../../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../../docs/design-analysis/design-decisions.md#dec-22), [DEC-25](../../../docs/design-analysis/design-decisions.md#dec-25), [DEC-27](../../../docs/design-analysis/design-decisions.md#dec-27), [DEC-35](../../../docs/design-analysis/design-decisions.md#dec-35)):
   - Ruby at the version in `.ruby-version`; `bundle install`; then `bin/run`.
   - Tests: `bundle exec rspec`; style check: `bundle exec rubocop`.
   - The three forms of the command, as the AC-09.1 table: no arguments (the sample files in `data/`, output in `output/`), 2 arguments (balances file, transfers file), 3 arguments (and the output file, used as given, missing folders created).
   - Typed paths are relative to the current folder; default paths are relative to the project root, so `bin/run` works from any folder.
   - The default output file `output/final_balances_YYYY-MM-DD_HHMMSS.csv`, named from the local date and time the run started; an existing output file is never overwritten: the run stops instead.
   - The usage message, exactly as in AC-09.2, for 1 argument or 4 or more (including `-h` and `--help`), with exit status 1:

     ```
     Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
     With no arguments, runs the sample files in data/.
     ```

   - The sample run's report, exactly as in AC-08.1, with its last line `Output file: output/final_balances_2026-11-07_143005.csv`, and one sentence saying that a real run shows its own date and time there (spec item 8).
2. `### On Windows` (FR-004): the program runs as `ruby bin/run`, with the same arguments; in PowerShell the exit status is in `$LASTEXITCODE`.
3. `### With Docker` (FR-005; [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../../docs/design-analysis/design-decisions.md#dec-37)): Docker is the alternative for a reviewer without Ruby 3.4. The commands of [dockerfile.md](dockerfile.md#commands-the-readme-gives) (build; run in a POSIX shell; run in PowerShell; tests), and one line each saying:
   - the container uses UTC for the file name unless `TZ` is set, so set it to your own time zone;
   - the mount keeps the output CSV on your machine, in `output/`;
   - your own files must be mounted into the container the same way as `output`, and their paths given as seen inside it (spec item 6);
   - on a Linux host the output file may belong to root, because the container runs as the image's default user.

### 2. `## Input files` (FR-006; [DEC-04](../../../docs/design-analysis/design-decisions.md#dec-04), [DEC-06](../../../docs/design-analysis/design-decisions.md#dec-06))

- Both files are CSV with no header row: balances `account number,balance`; transfers `from account number,to account number,amount`.
- A header row is a bad row: in the balances file it makes the file invalid and stops the run; in the transfers file that row is rejected and the run continues.

### 3. `## Log level and exit status` (FR-007, FR-008; [DEC-25](../../../docs/design-analysis/design-decisions.md#dec-25), [DEC-28](../../../docs/design-analysis/design-decisions.md#dec-28), [DEC-29](../../../docs/design-analysis/design-decisions.md#dec-29))

- `LOG_LEVEL`: `warn` (the default) or `info`, in any letter case; any other value falls back to `warn`.
- Log lines go to standard error, with account numbers masked as `************6789`; the report alone goes to standard output.
- Exit status 0: the run completed, even if some or all transfers were rejected. Exit status 1: the run stopped, for any reason in AC-09.8: wrong arguments, a missing or unreadable input file, an invalid balances file, an empty transfers file, a file that cannot be read past a line, a changed total, an output file that already exists, or an output file that cannot be written.

### 4. `## Assumptions` (FR-009; spec item 10)

The ten rows of [`design-decisions.md` Assumptions](../../../docs/design-analysis/design-decisions.md#assumptions), each with its reason, worded as there, with links to the decisions rewritten to `docs/design-analysis/design-decisions.md#dec-nn`.

### 5. `## Design` (FR-010; [DEC-30](../../../docs/design-analysis/design-decisions.md#dec-30), [DEC-31](../../../docs/design-analysis/design-decisions.md#dec-31), [DEC-18](../../../docs/design-analysis/design-decisions.md#dec-18), [DEC-09](../../../docs/design-analysis/design-decisions.md#dec-09))

- Light domain-driven design: the rules live inside the models (`AccountNumber`, `Money`, `Transfer`, `Account`, `AccountRepository`), with plain names and no ceremony.
- The three folders `lib/domain`, `lib/application` and `lib/infrastructure`, and what each does.
- The in-memory `AccountRepository` (`add`, `include?`, `find`, `all`).
- The parts passed in to `ProcessDailyTransfer` (the readers, the writer, the repository, the report printer, the logger and the run time), so tests pass fakes.
- Every check runs before any balance changes, so each transfer is all or nothing.
- Money as `Money` on `BigDecimal`, never floating point, never rounded.
- Links to `docs/design-analysis/design-decisions.md` and `docs/solution-design/README.md` for the rest.

### 6. `## Test coverage` (FR-012; [DEC-36](../../../docs/design-analysis/design-decisions.md#dec-36))

- The line SimpleCov prints, `Line coverage: <covered> / <total> (<percent>%)`, from a full `bundle exec rspec` run on the final code (plan item 10).
- The full report is in `coverage/index.html` after a test run.
- No minimum figure is set.

### 7. `## Storage, production and known limitations` (FR-011; [DEC-03](../../../docs/design-analysis/design-decisions.md#dec-03), [DEC-18](../../../docs/design-analysis/design-decisions.md#dec-18), [DEC-32](../../../docs/design-analysis/design-decisions.md#dec-32))

- (a) Persistent storage: to stay safe to rerun, a version with storage would have to remember which files and transfers were already applied, so a rerun cannot apply a day twice; remembering applied files across runs is out of scope.
- (b) Production items: very large files (streaming or chunking); a database repository with database transactions or sagas.
- (c) Known limitations, one line each, from [page 9's risks table](../../../docs/solution-design/09-considerations.md#risks-and-known-limitations) and [page 10](../../../docs/solution-design/10-traceability-glossary-assumptions.md#known-limitations): no memory of earlier runs; results held in memory; an unreadable line in the transfers file discards the whole day; a duplicate account whose first copy has an invalid balance is reported only after that row is fixed; a balances file missing an account rejects every transfer touching it as `unknown_account`; two default-path runs in the same second (the second stops); full account numbers on screen and in the output CSV; the Docker clock is UTC unless `TZ` is set; the total-check failure cannot happen with correct code, so it is tested with fakes.

### 8. `## How this was built` (FR-013; spec item 12)

- The design and the code were made with an AI assistant, in four steps, each with a link:
  1. design analysis: `docs/design-analysis/design-decisions.md`;
  2. solution design: `docs/solution-design/README.md`;
  3. GitHub Spec Kit specification: `.specify/memory/constitution.md` and `specs/`;
  4. test-first implementation through the Spec Kit tasks: `specs/` (each spec's `tasks.md`).
- The prompts that shaped them are in `docs/prompts/`.

### 9. `## Repository layout` (FR-014)

A table of the finished repository's paths and what each holds: `bin/run`, `lib/domain/`, `lib/application/`, `lib/infrastructure/`, `spec/`, `data/`, `output/` (created by a run, not committed), `docs/challenge/`, `docs/design-analysis/` (with `design-decisions.md`, `handwritten/` and `clarifications/`), `docs/solution-design/`, `docs/spec-kit/`, `docs/prompts/`, `specs/`, `.specify/` and `.claude/` (the Spec Kit set-up), `.github/workflows/ci.yml`, `Dockerfile`, `CLAUDE.md`. Plan item 16: the earlier "Status" section and the Google Sheet link are removed.

### 10. `## The challenge` (FR-014)

A link to `docs/challenge/MABLE_BACK_END_CODE_TEST.md`, with the two sample files kept unchanged beside it.

## The README check (C-31)

Read the finished README against each item; every item must be "present". The section order is part of R-01.

| ID | Item | FR | Present when |
|---|---|---|---|
| R-01 | Build, test and run come first; sections in the order above | FR-001 | Headings appear in the order 1 to 10 |
| R-02 | The three command forms, path rules, default output name, no overwrite, the usage message exactly | FR-002 | All five points present; usage lines equal AC-09.2 |
| R-03 | The sample report exactly as AC-08.1 | FR-003 | Character for character equal, run time `2026-11-07_143005` |
| R-04 | `ruby bin/run` on Windows | FR-004 | Present |
| R-05 | Docker: build, run (POSIX and PowerShell), tests; `TZ` and UTC; the mount; own files mounted; root on a Linux host; no `--user` | FR-005 | All present; commands equal [dockerfile.md](dockerfile.md#commands-the-readme-gives) |
| R-06 | Both file formats; no header; a header row is a bad row | FR-006 | Present |
| R-07 | `LOG_LEVEL` values, letter case, fallback; log lines on standard error, masked; report on standard output | FR-007 | Present; mask written `************6789` |
| R-08 | Exit statuses 0 and 1, with the AC-09.8 reasons | FR-008 | All eight reasons listed |
| R-09 | The ten assumptions with reasons, worded as in `design-decisions.md` | FR-009 | 10 of 10, same words |
| R-10 | The design reasoning and the links | FR-010 | Every point present; both links resolve |
| R-11 | Storage, production items, known limitations | FR-011 | (a), (b) and the nine limitations present |
| R-12 | Coverage line, `coverage/index.html`, no minimum | FR-012 | Present; figure equals C-33 |
| R-13 | "How this was built": AI assistant, four steps with links, `docs/prompts/` | FR-013 | Present; links resolve |
| R-14 | Layout table, challenge link, no "Status" or "To be added", no company whose balances are processed | FR-014 | Present; `grep -n -e 'To be added' -e '## Status' README.md` finds nothing |

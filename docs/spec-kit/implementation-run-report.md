# Spec Kit run report

The record of the Spec Kit run described in the [Spec Kit brief](spec-kit-brief.md). It is updated after every step.

Back to [project instructions](../../CLAUDE.md).

## Part 1: Specification

Started by [P24](../prompts/prompts-spec-creation-phase.md#p24), from the branch `spec-kit-setup`.

### Status

| Step | State |
|---|---|
| 1. Start | Done |
| 2. Constitution | Done |
| 3. Specs | Done |
| 4. Clarify, plan and tasks | In progress |
| 5. Cross-check | Not started |
| 6. Scripted checks | Not started |
| 7. Merge and push | Not started |
| 8. Stop | Not started |

### Check results

None yet.

### Decided in the run

- **Constitution**
  - Two extra sections, "Technology Constraints" and "Development Workflow", added to the template. The workflow section restates the brief's rule 5.
  - Principle V: an invalid balances file is found in full before any transfer runs, and a run that stops writes no output file. The unchanged total of all balances is under this principle too.
  - Principle VIII: exit statuses 0 and 1 are part of the output-channel principle. The usage message goes to stderr with errors and logs.
  - Governance: a departure from a principle needs justification in the plan. Design reasoning goes in the README, not in code comments. CLAUDE.md is the runtime guidance file.
- **001-domain**
  - Code lives under `lib/`, starting with `lib/domain/`.
  - Money error messages say "balance" for an opening balance and "amount" for a transfer amount. The domain owns this text.
  - Money keeps the text it was built from, so `-0` stays `-0`.
  - Text with a point and 3 or more decimals gets "has more than 2 decimal places". Other bad text gets "is not a valid amount".
  - The error messages for a zero or negative amount, same account, unknown account, duplicate account and insufficient funds are fixed in the spec.
  - When both accounts are unknown, the error names the from account.
  - The six reason codes are defined once in the domain.
  - Where page 2 gives no full output, the lines are marked "(derived)".
  - Each single-row example is the only row of `transfers.csv`, on line 1.
  - The exact Ruby 3.4.x version is set by the plan, not the spec.
- **002-file-runner**
  - Runner scenarios run in the same process, in a temporary folder. The test writes the CSV files there, so they are not fixture files. This keeps the end-to-end runs at 5.
  - The five end-to-end runs are AC-08.1, AC-08.2, AC-02.3, AC-01.4 and AC-09.2 (one argument).
  - AC-09.1 uses a stand-in `ProcessDailyTransfer`. AC-08.4 uses `../` paths from a subfolder.
  - AC-09.7 checks `default_path` for two run times one second apart, and checks that two runs give the same output.
  - AC-08.3 also reads the AC-08.2 output back in as a balances file.
  - The count is singular for one problem: "(1 problem)" and "1 problem".
  - Each run-stopping message is the text after "Error: ". The Runner adds only that prefix and the log line.
  - A malformed transfers row with 1 field logs `Line N rejected: <masked from> malformed_row`. The report keeps "malformed_row: <K> fields, expected 3" for every count.
  - Partial criteria from page 2 are completed in the spec.
  - Tests match the reason from the system as any non-empty text.
  - The test for an unreadable file must work on every OS the suite runs on. The plan picks the method.
  - One rule shows every path in the report, the messages and the log lines. The plan picks where it lives.
  - `LOG_LEVEL` is compared in any letter case, without trimming. Anything else falls back to warn.
  - 002 creates `data/` and `spec/fixtures/sample/` with copies of the sample files. `docs/challenge/` is unchanged.
  - The start check on the output path fails only when a file exists there. An existing folder fails at writing.
  - A transfers file whose first row cannot be read stops with UnreadableFile, not NoTransfers.
- **003-delivery**
  - In runs made by hand or by CI, `<run time>` is the real run time. Nothing else may differ from page 2.
  - A clean checkout is a fresh clone of the pushed branch into a new empty folder outside the working repository.
  - On Windows, the Output file line uses `/`, as page 2 shows.
  - `Gemfile.lock` lists the platforms needed for a frozen install on Windows, Ubuntu CI and Docker. The plan picks the list.
  - The Docker image is named `mable-transfers`, built from the full official `ruby:<version>` image. Its working folder is the project root.
  - The README says in one line that a reviewer's own input files must be mounted into the container, like the output.
  - `bin/run` is stored executable, with a `#!/usr/bin/env ruby` line and LF line endings. Every text file uses LF.
  - The README shows the sample report exactly as in AC-08.1, with the page 2 run time.
  - The CI workflow is `.github/workflows/ci.yml`, run on push to any branch, with RSpec and RuboCop as separate steps.
  - The README lists the ten assumptions, the known limitations from pages 9 and 10, and a "How this was built" section.
  - No `.dockerignore`. The Dockerfile adds nothing beyond DEC-36.
  - The README keeps the challenge link and an updated layout table, and replaces the Status and "To be added" sections.

### Changed in the run

None.

### Fixed in review

None yet.

### Left for the developer

None yet.

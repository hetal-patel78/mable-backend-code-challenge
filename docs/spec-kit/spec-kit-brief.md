# Spec Kit brief

The brief for step 3 of the [development approach](../../CLAUDE.md): the GitHub Spec Kit specification. Implementation (step 4) is Part 2 and follows Part 1. The developer's prompt for this brief is [P20](../prompts/prompts-spec-creation-phase.md#p20).

**Status: approved by the developer.**

## Set-up

- Spec Kit 1.2.6.dev0 is installed with the Claude integration and the PowerShell scripts: `.specify/` and the `/speckit-*` skills in `.claude/skills/`.
- The set-up is committed on the local branch `spec-kit-setup`, on top of the finished solution design, and is not pushed. Part 1 starts from that branch, so the set-up is pushed with the spec work, never with the solution design.
- The repository's GitHub remote is `origin` (`hetal-patel78/mable-backend-code-challenge`).
- On this machine the `specify.exe` launcher is blocked by Windows Application Control. If the `specify` command is needed, run it through the tool's own Python: `C:\Users\hets7\AppData\Roaming\uv\tools\specify-cli\Scripts\python.exe -c "import sys; sys.argv=['specify', <arguments>]; from specify_cli import main; main()"`. The PowerShell scripts in `.specify/scripts/powershell/` run normally.

## Shared rules

### 1. Sources

In order of precedence:

1. [`design-decisions.md`](../design-analysis/design-decisions.md): the source of truth.
2. [`docs/solution-design/`](../solution-design/README.md): the main input. Start from its README.
3. [`CLAUDE.md`](../../CLAUDE.md).

The handwritten analysis and the clarifications are background only, and agents do not need to read them.

### 2. Constitution

One constitution with lasting principles only, taken from the decisions and the rubric:

- domain models that encapsulate their own rules;
- separation of concerns: reading files, the domain and the output are apart;
- short, readable methods;
- tests first, with orthogonal RSpec specs that explain the behaviour;
- check everything before any balance changes;
- money exact to the cent;
- no over-engineering;
- standard output for results only.

Detailed rules stay in `design-decisions.md`, and the constitution points to it.

### 3. Specs

Each FR and NFR is owned by exactly one spec. The FRs are on [page 2](../solution-design/02-functional-requirements.md), the NFRs on [page 3](../solution-design/03-non-functional-requirements.md), and the split follows the [traceability on page 10](../solution-design/10-traceability-glossary-assumptions.md#traceability).

**Agreed: three specs**, built in this order: `001`, `002`, `003`.

| Spec | Owns | Builds | Pages it uses |
|---|---|---|---|
| `001-domain` | FR-03 Apply a transfer, FR-04 Below $0 and exactly $0, FR-05 Account not loaded, FR-06 Validation of account numbers and amounts, NFR-01 Money accuracy, NFR-02 Cost of each operation, NFR-05 Code organisation and readability | The project skeleton: `Gemfile`, `.ruby-version`, the folder layout, RSpec set-up with random order, SimpleCov, RuboCop with `rubocop-rspec`, `.gitignore`. The domain: `AccountNumber`, `Money`, `Account`, `Transfer`, `TransferResult`, `AccountRepository` (`add`, `include?`, `find`, `all`), `TransferService`, and the domain errors `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `NegativeBalance`, `UnknownAccount`, `DuplicateAccount`, `InsufficientFunds`. | 02 (FR-03 to FR-06), 03, 05, 06 (domain), 07.1 and 07.3 to 07.6, 08.1, 08.2, 09 (time and space, testing strategy), 10 |
| `002-file-runner` | FR-01 Load the balances file, FR-02 Read the transfers file, FR-07 Order of transfers, FR-08 End-of-day result and output, FR-09 The runner, NFR-03 Scale, NFR-06 Testability and coverage | The application layer: `LoadBalances`, `ProcessDailyTransfer`, `DayResult`, `InvalidBalancesFile`, `NoTransfers`, `TotalChanged`. The infrastructure layer: `BalancesCsvReader`, `TransfersCsvReader`, `FinalBalancesCsvWriter` (with the class method `default_path`), `ReportPrinter`, `Runner`, `UnreadableFile`, `OutputNotWritable`, and `bin/run`. The five end-to-end runs, including the challenge sample files with the exact closing balance of every account, and every page 2 scenario run through the runner. | 02 (FR-01, FR-02, FR-07 to FR-09, and every scenario for the runner tests), 03, 05, 06, 07 (all), 08.3 to 08.6, 09, 10 |
| `003-delivery` | NFR-04 Language version and portability | The README with its assumptions and "How this was built" ([DEC-37](../design-analysis/design-decisions.md#dec-37)), the coverage figure in it ([DEC-36](../design-analysis/design-decisions.md#dec-36)), the GitHub Actions workflow running RSpec and RuboCop, the Dockerfile, the Docker and Windows runs from a clean checkout, and a check of what the submission holds ([DEC-38](../design-analysis/design-decisions.md#dec-38)). No test-data files beyond those `002` needs. | 01, 03 (NFR-04), 04, 09 (portability and CI), 10 (assumptions, known limitations) |

**Why three.** One spec per FR and NFR was not chosen: the requirements share classes (for example FR-03 to FR-05 all go through `Account`, `TransferService` and `AccountRepository`), so separate specs would plan the same classes several times and clash in parallel worktrees, and every requirement, task and test already cites its FR, NFR and DEC IDs. Three specs keep each review small:

- the domain has no file, clock or terminal, so `001` can be specified and tested on its own, and `002` builds on a finished domain;
- `002` keeps `ProcessDailyTransfer` and the runner in one spec, so the class has one design;
- `003` is checked in a different way (CI, Docker, a clean checkout, the README's content), not by RSpec, and the README can only be finished once `001` and `002` are.

**Where a requirement crosses the line.**

- FR-01 is owned by `002`, but its account rules (`NegativeBalance`, `DuplicateAccount`, `AccountRepository#include?`) are built and unit-tested in `001`, where they live. `002` tests FR-01 through `LoadBalances` and the runner. The same holds for the domain errors behind FR-02 and FR-08.
- `002` runs every FR's page 2 scenario through the runner, including those owned by `001`; it does not own them.
- NFR-05 is owned by `001` because the skeleton sets RuboCop and the folder layout; every later spec must keep zero offences.

### 4. How the tests are split

- `001` tests each of its FRs by calling the domain directly: the result, the error class and its exact message, and that no balance changes after every failure.
- `002` runs every FR's [page 2](../solution-design/02-functional-requirements.md) scenario through the runner with real CSV files, with exact standard output, standard error and exit code. This includes the scenarios of the FRs that `001` owns; `002` runs them but does not own them.
- The domain owns the exact message text of every error. The runner never rewrites a message; it only adds what [page 9](../solution-design/09-considerations.md) says it adds (for example the line number).
- `003` is checked by CI, a Docker run and a Windows run from a clean checkout, and a check of the README against [DEC-37](../design-analysis/design-decisions.md#dec-37), not by new RSpec specs.

### 5. Rules

- No new behaviour, and nothing that is out of scope on [page 4](../solution-design/04-scope.md).
- Copy character for character anything a test compares: every message in page 9's table, the output format of every balance and line, and every exit code.
- Every acceptance scenario states standard output, standard error and the exit code separately, copied from page 2.
- Names and members exactly as on [page 6](../solution-design/06-components.md) and in the [page 10 glossary](../solution-design/10-traceability-glossary-assumptions.md#glossary). Where page 10 leaves a name open, the plan picks it and lists it under "Decided in the run".
- Technical choices are already made in `design-decisions.md`: the Ruby version, RSpec, Bundler, and the project layout on [page 5](../solution-design/05-high-level-design.md). Nothing else is added: no framework, no gems beyond those the decisions name (RSpec, RuboCop, `rubocop-rspec`, SimpleCov), no logging library.
- Tests come first in every tasks file, and each phase ends with its specs passing. Every edge case listed in `design-decisions.md` has a planned test.
- Every requirement, scenario, task and test cites its FR or NFR and DEC IDs where it helps.
- Decide small gaps yourself, write them into the spec and list them in the run report. No `[NEEDS CLARIFICATION]` may be left in any spec.
- Change `design-decisions.md` or the solution design only if it blocks a full, working, error-free system. Make the change in its own commit starting "Run change:", following the chain: the decision first, then the solution design, then the specs. The developer approved such changes in advance ([P23](../prompts/prompts-spec-creation-phase.md#p23)); each one is listed in the run report under "Changed in the run". Never pass by weakening a test or changing an expected output to match the code.
- Never delete anything, and keep the git history.
- Worktrees go in `C:\Dev\`, never inside the repository.
- Commit in small steps, each with a clear message naming what it covers. Push each spec's branch with its small commits kept, never as one big commit, and do not squash before pushing ([P22](../prompts/prompts-spec-creation-phase.md#p22)).
- Push `main` only after a separate review agent that did not write or fix the changes approves. Never force push.

### 6. Models

- Opus writes and reviews the specs, makes the decisions, and does the review before `main` is pushed.
- Sonnet fixes the findings in the specs.
- Haiku runs the scripted checks and updates the run report.
- A Haiku or Sonnet agent that fails the same task twice hands it to Opus.

### 7. Run report and logs

- The run report is `docs/spec-kit/implementation-run-report.md`, with a section for Part 1. It is written early and updated after every step, with: status, check results, decided in the run, changed in the run, fixed in review, and what is left for the developer.
- The inputs to each `/speckit-*` command go in `docs/spec-kit/specify-inputs.md`.
- The prompt that starts Part 1 is logged in [`prompts-spec-creation-phase.md`](../prompts/prompts-spec-creation-phase.md), numbered after the last prompt in `docs/prompts/`.

## Part 1: Specification

No code is written in Part 1. It runs in its own new session, on its own, without waiting for the developer, who reviews the specs after it. The developer has asked for Part 1 to run as a multi-agent workflow (the Workflow tool): the parallel steps (4, and the reviews and fixes in 5) run as workflow agents, with the models in rule 6.

1. **Start.** Work from the branch `spec-kit-setup`. Create the run report and log the starting prompt. Update the "Current stage" in `CLAUDE.md` to the Spec Kit specification.
2. **Constitution.** Write the constitution with `/speckit-constitution` (rule 2), then commit.
3. **Specs.** Create the three specs one after another with `/speckit-specify`, so they are numbered `001-domain`, `002-file-runner` and `003-delivery` (rule 3), and commit.
4. **Clarify, plan and tasks, in parallel.** For each spec, in its own worktree in `C:\Dev\`: run `/speckit-clarify`, `/speckit-plan` and `/speckit-tasks`. Review it with a reviewer that did not write it, fix every finding, then review again with a fresh reviewer that did not write or fix it. Repeat until a review finds 0 defects, with no limit on rounds. Then push that spec's branch. `002` plans against `001`'s plan for every domain name and message it uses.
5. **Cross-check.** Check the three specs together: the same names, strings and outcomes everywhere, each FR and NFR owned once, and no contradictions. Fix and check again until nothing is found.
6. **Scripted checks** on the whole specification:
   - every FR and NFR is covered;
   - exact strings, output channels and exit codes match page 2 and page 9;
   - names match page 6 and the page 10 glossary;
   - every edge case in `design-decisions.md` has a planned test;
   - `/speckit-analyze` reports no CRITICAL or HIGH issue;
   - there is no code under `lib/`, `bin/` or `spec/`.
7. **Merge and push.** Merge the spec branches into one specs branch, keeping the small commits, and push it. Then push `main` after the separate review (rule 5).
8. **Stop.** The run report says "Specification ready for review".

## Part 2: Implementation

Part 2 starts once Part 1's report says "Specification ready for review" and the assistant that started Part 1 has checked the specs. The developer does not need to approve the specs first. Part 2 runs as a multi-agent workflow (the Workflow tool), with the shared rules and the models in rule 6. Production code is written only through the Spec Kit tasks.

1. **Start.** Work from the pushed specs branch. Add a Part 2 section to the run report, log the starting prompt in `docs/prompts/prompts-implementation-phase.md`, numbered after the last prompt in `docs/prompts/`, and update the "Current stage" in `CLAUDE.md` to implementation.
2. **Implement, one spec after another**, in the order `001-domain`, `002-file-runner`, `003-delivery`, because each builds on the one before. For each spec, in its own worktree in `C:\Dev\`, branched from the previous spec's implementation:
   - run `/speckit-implement`, test first: write each task's spec, see it fail, then write the code that makes it pass;
   - each phase ends with every spec passing, in random order, and RuboCop reporting zero offences;
   - review the code and tests against the spec, plan, tasks, `design-decisions.md` and the rubric with a reviewer that did not write them; fix every finding; review again with a fresh reviewer that did not write or fix it; repeat until a review finds 0 defects;
   - push that spec's implementation branch with its small commits kept.
3. **Whole-system checks**, scripted:
   - `bundle exec rspec` passes, in random order, and the coverage figure is recorded;
   - `bundle exec rubocop` reports zero offences;
   - `bin/run` with no arguments, on the sample files, gives exactly the closing balances in [DEC-35](../design-analysis/design-decisions.md#dec-35), the report on page 2 and exit status 0;
   - every page 2 scenario gives the exact standard output, standard error and exit code;
   - `ruby bin/run` works on Windows; the Docker run is tested from a clean checkout if Docker is available, otherwise it is listed in the report as left for the developer;
   - after the push, the GitHub Actions run passes.
4. **Merge and push.** Merge the implementation branches into one implementation branch, keeping the small commits, and push it. Then push `main` after a separate review agent that did not write or fix the changes approves. Never force push.
5. **Stop.** The run report says "Implementation ready for review" and lists what is left for the developer, such as making the repository public for the submission ([DEC-38](../design-analysis/design-decisions.md#dec-38)).

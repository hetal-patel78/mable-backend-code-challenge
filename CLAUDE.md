# Mable Back End Code Challenge

Solution for the Mable back-end take-home challenge (`docs/challenge/MABLE_BACK_END_CODE_TEST.md`): load the starting account balances for one company from a CSV file, then apply one day's transfers from a second CSV file, never letting an account balance go below $0.

## Source of truth
- **`docs/design-analysis/design-decisions.md`** defines all behaviour and design. Implement exactly what the decisions say.
- If two decisions conflict, or a case is not covered by a decision and is more than a small decision under "Current stage", **stop and ask the developer**. Never invent behaviour.
- Every decision gets a stable ID (`DEC-nn`). Reference the ID in a code comment or test name where it makes the link clearer. In documents, link it as `design-decisions.md#dec-nn`, for example `design-decisions.md#dec-04`.

## Current stage
**Implementation.** The design analysis, the solution design and the GitHub Spec Kit specification are complete: `docs/design-analysis/design-decisions.md` is the single source of truth, `docs/solution-design/` is the main input, and the specs are in `specs/`. The code and tests are being written test-first through the Spec Kit tasks, following Part 2 of the developer's brief in `docs/spec-kit/spec-kit-brief.md`; the run is recorded in `docs/spec-kit/implementation-run-report.md`.

**Language and version:** Ruby, the latest 3.4.x release, tested with RSpec.

Design decisions belong to the developer. Once the design analysis has started, small decisions (edge cases, validation details, wording, test cases) may be made by the assistant when they are consistent with the developer's answers: record each in `design-decisions.md` with its reason and the rejected options, mark it as the assistant's pick, and list them for the developer to review. Anything that changes the design, conflicts with the developer's answers, or adds scope must be asked.

## Inputs that are not sources of truth
- The challenge as received, in `docs/challenge/`: `MABLE_BACK_END_CODE_TEST.md`, `mable_account_balances.csv` and `mable_transactions.csv`. Never edit them.
- Any brainstorm pages or notes the developer adds go in `docs/design-analysis/handwritten/` and are kept unchanged. Where they disagree with `design-decisions.md`, `design-decisions.md` wins.
- The developer's answers to review findings go in `docs/design-analysis/clarifications/`, kept unchanged, as the input to `design-decisions.md`. Where a later answer differs from an earlier one, the later one wins.

## Development approach
Each step is written from the one before it. Step 4 is in progress; each later step starts only when the developer says so.

1. **Design analysis (done):** review the developer's analysis against the challenge, raise findings (definite gaps, judgement calls, possible extras), agree answers with the developer, and consolidate them into `design-decisions.md`.
2. **Solution design document (done):** high-level design, components, logical flows, alternatives considered and trade-offs, in `docs/solution-design/`.
3. **GitHub Spec Kit specification (done):** constitution, spec, plan, tasks.
4. **Implementation (in progress):** test-first, through the Spec Kit tasks.

These rules apply:
- Precedence: `design-decisions.md`, then the solution design, then the Spec Kit files. If a later document contradicts an earlier one, point it out and ask; never resolve it quietly.
- The `/speckit-*` commands are run by the developer, or by Claude Code when a prompt the developer approved says so. Production code is written only through the Spec Kit tasks.
- The constitution holds lasting principles only; the detailed rules live in `design-decisions.md`.

## What the challenge is assessed on
Keep the rubric in `docs/challenge/MABLE_BACK_END_CODE_TEST.md` in view at every step:
- **Data structure:** uses domain models; uses native data structures readably.
- **Tests:** uses RSpec; has some coverage, then good coverage; tests are orthogonal; tests explain the functionality.
- **Object orientation:** models encapsulate logic appropriately; respects separation of concerns; short methods; readable methods.
- **General:** runs and provides feedback; calculates the test files accurately.

## Changing a decision
- Only after the developer confirms it.
- Record it only in `design-decisions.md`, worded as the decision itself, with no history notes such as "changed from" or "previously".

## Prompt log
The design and code are generated with an AI assistant, so the prompts that shaped them are kept.
- One file per phase, in `docs/prompts/`:
  - Initial analysis and setup (project instructions, analysis inputs): `prompts-initial-analysis-and-setup-phase.md`.
  - Design phase (design analysis and solution design): `prompts-design-phase.md`.
  - Spec creation phase (Spec Kit specification): `prompts-spec-creation-phase.md`.
  - Implementation phase: `prompts-implementation-phase.md`. Complete; no longer the current log.
  - Review and refactor phase (the developer's review after implementation): `prompts-refactor-phase.md`. This is the current log.
- Log a prompt when the developer makes a decision or gives an instruction about the solution, its design or how it is built. Quote it exactly as typed, typos included, and note its outcome.
- Numbering runs across all the logs: number a new prompt after the last one in any log.

## Scope
- Build only what the decisions describe. Anything marked out of scope needs the developer's approval first.
- If a change seems to need something the decisions do not cover, ask before adding it.

## Commits and pushing
- Commit locally only when the developer asks.
- Never push without the developer's approval.
- Before a push, squash the small local commits into a few meaningful, incremental commits, each with a clear message describing a coherent piece of work. Do not squash everything into a single commit: reviewers look for clear, incremental history.
- Show the squash plan (which commits fold together and the new messages) and wait for the developer's approval before rewriting history.

## Submission
- The submission format is decided during the design analysis.
- A `README.md` at the repository root gives build, test and run instructions and lists the assumptions.

## Build and test
- Install: `bundle install`
- Test: `bundle exec rspec`
- Style: `bundle exec rubocop`
- Run: `bin/run` (`ruby bin/run` on Windows)
- Docker and the arguments: see `README.md`.

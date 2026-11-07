# Spec Kit command inputs

The input given to each `/speckit-*` command in the Spec Kit run, as described in the [Spec Kit brief](spec-kit-brief.md) (rule 7). Each section holds the text passed to the command, and for `/speckit-clarify` the questions and the answers chosen.

Back to the [run report](implementation-run-report.md).

## Constitution

### `/speckit-constitution`

```text
Project name: Mable Back End Code Challenge. Version 1.0.0, ratified 2026-11-07, last amended 2026-11-07.

Write lasting principles only, in plain, clear English, taken from the design decisions and the assessment rubric in docs/challenge/MABLE_BACK_END_CODE_TEST.md. The detailed rules stay in docs/design-analysis/design-decisions.md (DEC-01 to DEC-38); the constitution points to it and does not copy them.

Principles:
1. Domain models encapsulate their own rules. Each rule lives in the model it belongs to (account number, money, transfer, account, repository), with plain domain names and no ceremony (DEC-30, DEC-31).
2. Separation of concerns. Reading files, the domain and the output are kept apart, in the domain, application and infrastructure layers. The domain knows no file, clock or terminal (DEC-30).
3. Short, readable methods. Code reads as the domain; RuboCop with rubocop-rspec reports zero offences (DEC-36).
4. Tests first. Every behaviour is specified by a failing RSpec spec before the code is written. Specs are orthogonal (each rule tested once, at the level where it lives) and explain the behaviour (DEC-34).
5. Check everything before any balance changes. A transfer is all or nothing; a stopped run writes nothing (DEC-12, DEC-18, DEC-25).
6. Money exact to the cent. BigDecimal inside a Money model, never floating point, never rounded or truncated (DEC-09).
7. No over-engineering. Build only what the decisions describe; nothing out of scope (DEC-02, DEC-03, out-of-scope list).
8. Standard output for results only. The report goes to stdout; errors, usage and log lines go to stderr; exit status 0 for a completed run, 1 for a stopped run (DEC-25, DEC-26, DEC-28).

Technology constraints, only those the decisions fix: Ruby, the latest 3.4.x release; RSpec; Bundler with a committed Gemfile.lock; runtime code uses the Ruby standard library only (csv, bigdecimal and logger listed in the Gemfile); development gems rspec, simplecov, rubocop and rubocop-rspec; no other gems, no framework, no logging library beyond Ruby's standard Logger (DEC-01, DEC-28, DEC-36).

Governance: precedence is design-decisions.md, then the solution design in docs/solution-design/, then the Spec Kit files (this constitution, specs, plans, tasks). A later document that contradicts an earlier one is pointed out and resolved by changing the earlier source first, never quietly. Decisions change only with the developer's confirmation. Every plan has a Constitution Check against these principles. Amendments use semantic versioning.
```

## 001-domain

### `/speckit-specify`

Pending.

### `/speckit-clarify` (001-domain)

Pending.

### `/speckit-plan` (001-domain)

Pending.

### `/speckit-tasks` (001-domain)

Pending.

## 002-file-runner

### `/speckit-specify`

Pending.

### `/speckit-clarify` (002-file-runner)

Pending.

### `/speckit-plan` (002-file-runner)

Pending.

### `/speckit-tasks` (002-file-runner)

Pending.

## 003-delivery

### `/speckit-specify`

Pending.

### `/speckit-clarify` (003-delivery)

Pending.

### `/speckit-plan` (003-delivery)

Pending.

### `/speckit-tasks` (003-delivery)

Pending.

## Whole specification

### `/speckit-analyze`

Pending.

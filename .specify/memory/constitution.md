# Mable Back End Code Challenge Constitution

This constitution holds the lasting principles for building the solution to the Mable back-end
challenge (`docs/challenge/MABLE_BACK_END_CODE_TEST.md`). The detailed rules are not repeated
here: they live in [`docs/design-analysis/design-decisions.md`](../../docs/design-analysis/design-decisions.md)
(DEC-01 to DEC-38), which is the source of truth. Each principle names the decisions behind it.

## Core Principles

### I. Domain Models Encapsulate Their Own Rules

- Every business rule lives in the model it belongs to: the account number, money, the
  transfer, the account and the repository each guard their own rules (DEC-30, DEC-31).
- Models use plain domain names. There are no base classes, no pattern suffixes and no extra
  ceremony such as factories, commands or domain events (DEC-30).
- Native Ruby data structures are used where they read clearly; a model is added only when it
  holds a rule.

Rationale: the rubric asks for domain models that encapsulate logic appropriately, and one home
per rule means each rule is written, tested and changed in one place.

### II. Separation of Concerns

- Reading files, the domain and the output are kept apart, in three layers: `domain`,
  `application` and `infrastructure` (DEC-30).
- The domain knows nothing about files, the clock, the terminal or the logger. File readers,
  writers, the report printer, the logger and the run time are passed in, never reached for.
- Checks on the shape of a file row belong to the file-reading layer; checks on values and
  balances belong to the domain.

Rationale: the rubric asks for separation of concerns, and passing the outside world in keeps
every part testable on its own.

### III. Short, Readable Methods

- Methods are short, do one thing and read as the domain they describe.
- Code is clear without comments that explain the design; the design reasoning goes in the
  README (DEC-30, DEC-37).
- RuboCop, with its default settings and `rubocop-rspec`, reports zero offences (DEC-36).

Rationale: short and readable methods are rubric items, and RuboCop makes them a checked rule
rather than a matter of taste.

### IV. Tests First (NON-NEGOTIABLE)

- Every behaviour is specified by an RSpec spec that is written and seen to fail before the
  code that makes it pass.
- Specs are orthogonal: each rule is tested once, at the level where it lives, and fixture files
  are used only for file-level behaviour (DEC-34).
- Spec names and examples explain the behaviour, so the specs read as a description of the
  system. Specs run in random order and must pass in any order.
- Every edge case in `design-decisions.md` has a test, and the sample files give exactly the
  closing balances in DEC-35.

Rationale: the rubric asks for RSpec, good coverage, orthogonal tests and tests that explain the
functionality; writing them first keeps the code to what the tests require.

### V. Check Everything Before Any Balance Changes

- Every check and lookup for a transfer runs before any balance changes, so a transfer is applied
  in full or not at all, and a rejected transfer leaves every balance unchanged (DEC-18).
- An invalid balances file is found in full before any transfer runs, and a run that stops
  writes no output file, so a partly applied day is never kept (DEC-04, DEC-12, DEC-25).
- The total of all balances is the same before and after the transfers (DEC-24).

Rationale: the system moves money; checking before changing makes each transfer safe with
nothing to undo.

### VI. Money Exact to the Cent

- Amounts and balances are exact decimal values inside the `Money` model, built on `BigDecimal`,
  never floating point (DEC-09).
- A value is never rounded or truncated; a value the rules do not accept is rejected.
- Money is always shown and written with exactly 2 decimal places.

Rationale: a balance off by one cent fails "calculates test files accurately", and rejecting
instead of rounding never changes the amount the company asked for.

### VII. No Over-Engineering

- Build only what the decisions describe. Anything out of scope in `design-decisions.md` or on
  the solution design's scope page is not built (DEC-02, DEC-03).
- Choose the simplest design that meets the decisions; a new folder, class or abstraction must
  hold a rule or a clear responsibility.
- Production concerns the decisions leave out (storage, very large files, transactions) are
  described in the README, not built.

Rationale: a small program judged on readability gains nothing from machinery it does not need.

### VIII. Standard Output for Results Only

- Standard output carries only the run's result: the report of a completed run (DEC-26).
- Errors, the usage message and log lines go to standard error (DEC-23, DEC-28).
- Exit status 0 means the run completed, even with rejected transfers; exit status 1 means the
  run stopped (DEC-25).

Rationale: the rubric asks that the program "runs and provides feedback", and keeping results
apart from errors lets a person or a script rely on each channel.

## Technology Constraints

Only the choices the decisions already fix (DEC-01, DEC-28, DEC-36):

- Ruby, the latest 3.4.x release, pinned in `.ruby-version`.
- Bundler, with `Gemfile.lock` committed.
- Runtime code uses the Ruby standard library only; `csv`, `bigdecimal` and `logger` are listed
  in the Gemfile.
- Development gems: `rspec`, `simplecov`, `rubocop` and `rubocop-rspec`.
- Logging uses Ruby's standard `Logger`.
- No other gems, no framework and no logging library are added.

## Development Workflow

- Work follows the Spec Kit flow: specification, plan, tasks, then implementation. Production code
  is written only through the Spec Kit tasks.
- Each phase of a tasks file starts with its specs and ends with every spec passing, in random
  order, and RuboCop reporting zero offences.
- Every requirement, scenario, task and test cites its FR or NFR and DEC IDs where that makes the
  link clearer.
- Anything a test compares (messages, output lines, balances and exit codes) is copied character
  for character from the solution design.
- Changes are reviewed against the specs, the plan, the tasks, `design-decisions.md` and the
  rubric by a reviewer who did not write them.

## Governance

- Precedence: `design-decisions.md` first, then the solution design in `docs/solution-design/`,
  then the Spec Kit files (this constitution, the specs, plans and tasks). If a later document
  contradicts an earlier one, the contradiction is pointed out and resolved in the earlier source
  first; it is never resolved quietly.
- This constitution holds lasting principles only. The detailed rules stay in
  `design-decisions.md`, and a decision changes only with the developer's confirmation.
- Every plan includes a Constitution Check against these principles, and every review checks
  compliance. Any departure from a principle must be justified in the plan or it is not allowed.
- Amendments are made in this file, with the version raised by semantic versioning: MAJOR for
  removing or redefining a principle, MINOR for a new principle or section, PATCH for wording.
- Runtime guidance for the assistant is in `CLAUDE.md`.

**Version**: 1.1.0 | **Ratified**: 2026-11-07 | **Last Amended**: 2026-11-09

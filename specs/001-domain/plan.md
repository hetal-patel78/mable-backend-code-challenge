# Implementation Plan: Domain and project skeleton

**Branch**: `001-domain` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-domain/spec.md`. The `/speckit-plan` input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#speckit-plan-001-domain).

## Summary

Build the project skeleton (Ruby 3.4, Bundler, RSpec, SimpleCov, RuboCop with `rubocop-rspec`) and the domain layer in `lib/domain/`: `AccountNumber`, `Money`, `Account`, `Transfer`, `AccountRepository`, `TransferService` and the seven domain errors. `TransferResult` (FR-022 to FR-025), the application's record of each row's outcome, is specified here but lives in `lib/application/` and is kept by `002-file-runner` (DEC-19). Each business rule lives in exactly one model ([DEC-30](../../docs/design-analysis/design-decisions.md#dec-30)), money is exact on `BigDecimal` ([DEC-09](../../docs/design-analysis/design-decisions.md#dec-09)), and a transfer finds both accounts, withdraws and then deposits, so it is all or nothing ([DEC-18](../../docs/design-analysis/design-decisions.md#dec-18)). The domain has no file, clock, terminal, logger or line number; it is tested test-first by calling it directly with builders ([DEC-34](../../docs/design-analysis/design-decisions.md#dec-34)). The application and infrastructure layers, `bin/run` and the end-to-end runs are built by `002-file-runner`, which uses the public members fixed in [contracts/domain-api.md](contracts/domain-api.md).

Owns: FR-03, FR-04, FR-05, FR-06, NFR-01, NFR-02, NFR-05.

## Technical Context

Every choice below is already made in `design-decisions.md` or on [page 5](../../docs/solution-design/05-high-level-design.md); nothing is added.

**Language/Version**: Ruby 3.4.12, the latest 3.4.x release on 2026-11-08, pinned in `.ruby-version` (DEC-01; decided in the run, D1).

**Primary Dependencies**: runtime: the Ruby standard library only; `csv`, `bigdecimal` and `logger` are listed in the `Gemfile` because they are bundled gems (DEC-01). This spec uses only `bigdecimal` at run time. Development and test: `rspec`, `simplecov`, `rubocop`, `rubocop-rspec` (DEC-36). Bundler, with `Gemfile.lock` committed (DEC-01). No other gem, framework or logging library.

**Storage**: none. Accounts are held in memory for one run only (DEC-03, DEC-31).

**Testing**: RSpec, random order with the seed printed, documentation format (DEC-34); SimpleCov coverage on every run, no minimum (DEC-36). Domain specs only in this spec, in `spec/domain/`, one spec file per class, using builders from `spec/support/` and no files.

**Target Platform**: any machine with Ruby 3.4 (Linux in CI and Docker, Windows and macOS by hand); the domain has no platform-specific code. Portability itself is NFR-04, owned by `003`.

**Project Type**: command-line program; this spec builds its domain library layer and the project skeleton.

**Performance Goals**: growth rates only (NFR-02): `add`, `include?` and `find` O(1); applying one transfer O(1); `all` O(m), visiting each account once ([page 9 time and space](../../docs/solution-design/09-considerations.md#time-and-space)). No timing test.

**Constraints**: money never passes through floating point, is never rounded or truncated, and has no upper limit (DEC-09, NFR-01). RuboCop default settings plus `rubocop-rspec`, zero offences, so at most 10 lines per method (DEC-36, NFR-05). The domain must not read files, print, log, read the clock or know line numbers (DEC-30).

**Scale/Scope**: one company's accounts and one day's transfers (DEC-02, DEC-32); 6 domain classes, 7 errors, 7 code files and 6 spec files.

## Constitution Check

*GATE: checked before Phase 0 and again after Phase 1. Against [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) v1.1.0.*

| Principle | How this plan meets it | Pre-design | Post-design |
|---|---|---|---|
| I. Domain models encapsulate their own rules | 16 digits in `AccountNumber`; money format in `Money`; amount above $0 and different accounts in `Transfer`; no overdraft and opening balance not negative in `Account`; no duplicate and unknown account in `AccountRepository` (FR-028). Plain names from page 6; no base classes, suffixes, factories, commands or events. Native `Hash` in the repository. | PASS | PASS ([data-model.md](data-model.md) lists one home per rule) |
| II. Separation of concerns | Only `lib/domain/` is created. The domain takes trimmed text and gives values and errors; it knows no file, clock, terminal, logger or line number (FR-029). Row-shape checks (`malformed_row`, header hint) stay in `002`'s readers; the domain only stores the reason and hint it is given. | PASS | PASS |
| III. Short, readable methods | RuboCop default settings with `rubocop-rspec`, zero offences, 10 lines per method (FR-031). No design reasoning in comments; each class has a one-line comment saying what it is, which RuboCop's default `Style/Documentation` requires (D16). | PASS | PASS |
| IV. Tests first (non-negotiable) | Every task phase writes the spec first, runs it and sees it fail, then writes the code; each phase ends with every spec passing in random order and RuboCop clean. One rule tested once, in the spec of the class where it lives (DEC-34). Every edge case in the spec has a planned test, citing its DEC ID. | PASS | PASS |
| V. Check everything before any balance changes | `TransferService#apply` finds both accounts, then `withdraw` compares before it changes the balance, then `deposit`, which cannot fail for a valid transfer (DEC-18). A refused transfer leaves both balances unchanged; tests check this for every refusal. | PASS | PASS |
| VI. Money exact to the cent | `Money` on `BigDecimal`, built from text by a strict pattern, never from a `Float`; written with exactly 2 decimals by string padding, never `format('%.2f')`; never rounded (DEC-09; [research.md](research.md) R5, R6). | PASS | PASS |
| VII. No over-engineering | Only the classes page 6 names; errors as plain `StandardError` subclasses in one file; no namespace module, no base error class, no extra gems. | PASS | PASS |
| VIII. Standard output for results only | The domain writes nothing to any stream; output belongs to `002`. | PASS (not applicable to the domain) | PASS |
| Technology constraints | Ruby 3.4.x pinned; Bundler with the lock committed; runtime standard library only; the four development gems; nothing else. | PASS | PASS |
| Development workflow | Tasks only through `/speckit-tasks`; tests first; IDs cited; exact messages copied from the spec's message table. | PASS | PASS |

No violation, so Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-domain/
├── spec.md              # /speckit-specify and /speckit-clarify output
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── domain-api.md    # Phase 1 output: the public domain members 002 uses
├── checklists/
│   └── requirements.md  # /speckit-specify output
└── tasks.md             # /speckit-tasks output
```

### Source Code (repository root)

Created by this spec. The layout follows [page 5](../../docs/solution-design/05-high-level-design.md#the-three-layers) and [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34); `lib/` is the parent folder decided in the spec (spec, decided in the run, item 1).

```text
.ruby-version                 # 3.4.12
.rspec                        # --require spec_helper, --format documentation
.rubocop.yml                  # plugins: rubocop-rspec (default settings otherwise)
.gitignore                    # coverage/ and output/
Gemfile                       # csv, bigdecimal, logger; dev/test: rspec, simplecov, rubocop, rubocop-rspec
Gemfile.lock                  # committed; platforms x86_64-linux and x64-mingw-ucrt (003 completes the list)

lib/
└── domain/
    ├── errors.rb             # the seven domain errors
    ├── account_number.rb     # AccountNumber
    ├── money.rb              # Money
    ├── account.rb            # Account
    ├── transfer.rb           # Transfer
    ├── account_repository.rb # AccountRepository
    └── transfer_service.rb   # TransferService

spec/
├── spec_helper.rb            # SimpleCov first, lib/ on the load path, random order, support files
├── support/
│   └── builders.rb           # Builders: valid-by-default domain objects, and attempt
└── domain/
    ├── account_number_spec.rb
    ├── money_spec.rb
    ├── account_spec.rb
    ├── transfer_spec.rb
    ├── account_repository_spec.rb
    └── transfer_service_spec.rb
```

Added later, not by this spec: `lib/application/` (including `transfer_result.rb`, `002` Phase 14), `lib/infrastructure/`, `bin/run`, `data/`, `spec/application/`, `spec/infrastructure/`, `spec/acceptance/`, `spec/fixtures/` (`002`); the README's content, CI workflow and Dockerfile (`003`); the completed `PLATFORMS` list of `Gemfile.lock` (`003`, plan item 2, which changes no gem version).

**Structure Decision**: a single Ruby project with code under `lib/` in the three layer folders of DEC-30, of which this spec creates `lib/domain/` only, and specs under `spec/` mirroring the code, one spec file per class (DEC-34). The errors hold only their messages, so `errors.rb` has no spec file; each error and its exact message are tested in the spec of the class that raises it (D3, D21).

## Design overview

The public members, their arguments and the exact messages are in [contracts/domain-api.md](contracts/domain-api.md); fields, rules and relationships are in [data-model.md](data-model.md); the reasoning for each technical choice is in [research.md](research.md).

- **`AccountNumber.new(text)`**: a `Data` record with the member `text`; valid when `text` matches `\A[0-9]{16}\z`; equal, `eql?` and `hash` by text; `to_s` gives the text (FR-001, FR-002; D23).
- **`Money.amount(text)` / `Money.balance(text)`**: parse text by the DEC-09 pattern into a `BigDecimal`; the class method names the word used in messages (`amount` or `balance`); `text` is the text as written when one was given and `to_s` otherwise; `negative?` is true when a minus sign was written (checked only when there is written text) or the amount is below 0; `positive?`; `+`, `-`, `<=>` with `Comparable`; equality by amount; `to_s` with exactly 2 decimals (FR-003 to FR-007).
- **`Account.new(number, balance)`**: runs `Account.check_opening_balance(balance)` (raises `NegativeBalance`); `withdraw(money)` checks before it changes; `deposit(money)` cannot fail for a valid transfer; both raise `ArgumentError` for an amount of $0 or less (FR-010 to FR-013; D24).
- **`Transfer.new(from:, to:, amount:)`**: a `Data` record with the members `from`, `to` and `amount`; `InvalidAmount` unless `amount.positive?`, then `SameAccount` if `from == to` (FR-008, FR-009).
- **`AccountRepository`**: a `Hash` keyed by `AccountNumber`; `add`, `include?`, `find`, `all` (FR-014 to FR-018, FR-033).
- **`TransferService.new(repository)#apply(transfer)`**: find from, find to, withdraw, deposit (FR-019 to FR-021, FR-034).

Each message has one owner in the domain: the error class itself where the message has one form, or `Money` and `Transfer` for the forms of `InvalidAmount` (D21). Every message matches the [spec's message table](spec.md#domain-error-messages) character for character (FR-027).

## Test approach

- **Tests first.** Each task phase writes the spec file, runs `bundle exec rspec <file>` and sees it fail (a missing class or a failed expectation), then writes the code until the phase's specs pass in random order and `bundle exec rubocop` reports zero offences.
- **One rule, one place, one test.** Each rule is tested in the spec of the class that owns it (DEC-34): the 16-digit rule only in `account_number_spec.rb`, the money format only in `money_spec.rb`, and so on. `transfer_service_spec.rb` tests the order of the steps and all-or-nothing, not the rules behind each error again; it uses one example of each error to show the order and the unchanged balances.
- **What every refusal test checks** (brief rule 4): the error class and its exact message in one example, and in a separate example that the balances (and, for the service, the repository's accounts) are unchanged.
- **RuboCop's RSpec defaults shape the specs** (D17): one expectation per example (`RSpec/MultipleExpectations`), examples of at most 5 lines (`RSpec/ExampleLength`), at most 3 levels of nesting. Balances are compared as one array of strings, for example `expect(balances).to eq(%w[100.00 50.00 0.00])`; an unchanged balance after a refusal uses the `attempt(error_class) { ... }` helper from `spec/support/builders.rb`, which runs a block and rescues only the named error, so the refusal and the unchanged balances are separate examples.
- **Table-driven examples** for the value rules: each row of the spec's AC-06.1, AC-06.2 and AC-06.3 tables is one example, generated from a list in the spec file, so the test names read as the rules.
- **Edge cases**: every edge case in the spec's Edge Cases list has a named example in `tasks.md`, citing its DEC ID.
- **No `002` behaviour is tested here**: no reading of rows, no line numbers in messages, no reason-code mapping, no report.

## Decided in the run

Names and details that page 6 and the page 10 glossary leave open, and small technical gaps, decided consistently with `design-decisions.md`. Each is for the developer's review. Reasons and rejected options are in [research.md](research.md) where they need more than a line.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| D1 | Ruby 3.4.12 in `.ruby-version`: the latest 3.4.x release listed at `cache.ruby-lang.org` on 2026-11-08 | DEC-01, FR-036 | DEC-01 says the latest 3.4.x; spec item 14 leaves the number to the plan | An older 3.4.x; Ruby 4.0 |
| D2 | No namespace module: every class and error is a top-level constant with its page 6 name | DEC-30, FR-030 | The names stay exactly as on page 6, and the program is small; a module would only add a prefix | A `Mable` or `Domain` module |
| D3 | The seven errors are defined in one file, `lib/domain/errors.rb`, each a direct subclass of `StandardError`, with no spec file of its own | DEC-30, FR-026, FR-038 | Each holds only its message (D21), so it is tested where it is raised, with the exact message. DEC-30 rules out base classes, so there is no shared domain-error parent | One file per error; a `DomainError` base class |
| D4 | `Money` is built from text by two class methods, `Money.amount(text)` and `Money.balance(text)`, which set the word used in its messages | DEC-09, spec item 2 | The caller names what the value is, and the domain owns the message wording; reads as the domain | A `label:` keyword; a separate class per kind |
| D5 | `Money` members: `text` (the written text, or `to_s` for a computed value), `to_s`, `+`, `-`, `<=>` with `Comparable`, `==`, `eql?`, `hash` (a zero hashes as `BigDecimal('0').hash`, so `-0` and `0` hash alike), `negative?`, `positive?`; `Money.new(value, text = nil)` builds a value from a `BigDecimal` and is used by the class methods and by `+` and `-` | DEC-09, FR-003 to FR-007, spec item 16 | The fewest members that the domain and `002` need (sums, comparison, the $0 checks, writing); `negative?` is true when a minus sign was written or the amount is below 0, so `-0` counts as negative and `5.00 - 5.00` does not | Exposing the `BigDecimal`; a `zero?` member (not needed) |
| D6 | `Account.new(number, balance)` with positional arguments; readers `number` and `balance` | page 6 `Account` | Two required values, read in the order page 6 lists them | Keyword arguments |
| D7 | The class-level opening-balance check is `Account.check_opening_balance(balance)`; it returns nothing and raises `NegativeBalance` | page 6 `Account`, page 10 pick 26, FR-013 | Names what it does; `Account.new` calls it, so the rule is in one place | `validate_balance`, `opening_balance!` |
| D8 | `Transfer.new(from:, to:, amount:)` with keyword arguments; readers `from`, `to`, `amount` | page 6 `Transfer` | Keywords stop the two account numbers being swapped by mistake | Positional arguments |
| D9 | `TransferResult.applied(line_number:, fields:)` and `TransferResult.rejected(line_number:, fields:, reason:, header_hint: nil)`; readers `line_number`, `fields`, `reason` (nil when applied), `header_hint` (nil unless given); predicates `applied?` and `rejected?` | DEC-19, FR-022, FR-023 | Two named ways to build the two outcomes; an applied result cannot carry a reason or a hint | One constructor with an `applied:` flag |
| D10 | `TransferResult::REASON_CODES` is a frozen list of the six reason codes as symbols, in DEC-19 order; `rejected` raises `ArgumentError` for any other reason | DEC-19, FR-022, FR-024 | One place for the list (spec item 11); a reason outside the list is a programming error, not a domain error, so it gets Ruby's own error class | Strings; no guard (a typo would reach the report) |
| D11 | The header hint text is passed in by the caller as `header_hint:`; the domain does not define the hint text | DEC-06, FR-023 | The hint comes from the reader's header mark (`002`), and the same text is used by `LoadBalances`; one owner for the text | A constant in `TransferResult` (a second owner) |
| D12 | `TransferService.new(repository)` and `TransferService#apply(transfer)`; `apply` returns nil | page 6 `TransferService`, DEC-18 | The repository is the part it works on, the transfer is the request; success is "no error" | `call`; passing the repository on every call |
| D13 | Code files load their own dependencies with `require_relative`, and only those whose constants they name; `spec_helper.rb` puts `lib/` on the load path and specs `require 'domain/<file>'` for the class under test and for every other code file whose constant they name (for example `domain/errors`), so each spec loads on its own; `.rspec` holds `--require spec_helper` | DEC-34 | Each file states what it uses; specs read the same way as the code's layers | `require_relative '../../lib/...'` in every spec; one file that requires everything |
| D14 | `Gemfile`: the runtime gems at top level, the four tools in `group :development, :test`, with no version constraints; `Gemfile.lock` pins the versions; this spec adds the two platforms its own runs need, `x86_64-linux` and `x64-mingw-ucrt`, and `003` completes the `PLATFORMS` list (`003` plan item 2) | DEC-01, DEC-36, FR-037 | The lock is the one place for versions; the two platforms let this spec's suite run on Linux and Windows from the same lock, and `003` adds the rest (`ruby`, `aarch64-linux`, `x86_64-darwin`, `arm64-darwin`) so Docker on ARM64 and macOS also install it frozen | Version constraints in the `Gemfile` as well; a lock for one platform only |
| D15 | `.rubocop.yml` holds only `plugins: [rubocop-rspec]`; every other setting is RuboCop's default, and the target Ruby version comes from `.ruby-version` | DEC-36, FR-031 | DEC-36 asks for default settings with `rubocop-rspec`; the plugin must be declared to load | Enabling new cops; changing limits |
| D16 | Every code and spec file starts with `# frozen_string_literal: true`, and every class has a one-line comment saying what it is (from the page 10 glossary) | DEC-30, DEC-36, FR-032 | RuboCop's defaults require both; a one-line "what it is" is not design reasoning, which stays in the README | Disabling `Style/Documentation` (changes the defaults) |
| D17 | Specs follow `rubocop-rspec` defaults: one expectation per example, a short `attempt(error_class)` helper that runs a refused call and rescues only that error, and balances compared as one array | DEC-34, DEC-36 | Keeps tests orthogonal and the style check clean without changing settings | `aggregate_failures` everywhere; disabling `RSpec/MultipleExpectations` |
| D18 | "`deposit` is never called" (AC-04.1, AC-05.1) is proven by the to account's balance staying unchanged, not by a spy | DEC-18, DEC-34 | Tests the outcome, not the internals, and stays valid if the method is renamed | Message spies on `Account` |
| D19 | `AccountNumber`, `Money`, `Transfer` and `TransferResult` cannot change once built: `AccountNumber`, `Transfer` and `TransferResult` are `Data` records, frozen by Ruby, and `Money` freezes itself; `TransferResult#fields` is a frozen copy | page 6 (value models never change), DEC-30 | A value that cannot change cannot be broken by a caller | Leaving them mutable |
| D20 | SimpleCov starts at the top of `spec_helper.rb`, before any code is loaded, with `add_filter '/spec/'` | DEC-36, FR-040 | Coverage counts only the code, and every file is measured | A `.simplecov` file (one more file) |
| D21 | An error with one message form builds its message from the values it is given: `InvalidAccountNumber.new(text)`, `SameAccount.new(account_number)`, `NegativeBalance.new(balance)`, `UnknownAccount.new(account_number)`, `DuplicateAccount.new(account_number)`, `InsufficientFunds.new(account_number, amount, balance)`. `InvalidAmount` has four message forms from two raisers (`Money`, `Transfer`), so it is raised with its full message | DEC-12, DEC-30, FR-027 | Each message has one owner in the domain. `LoadBalances` (`002`) reports a duplicate before the balance check, without calling `add` (DEC-12, page 6 step 3), so it takes the text as `DuplicateAccount.new(number).message` instead of writing it again | Every raiser building the message (the duplicate text would be written twice, in `AccountRepository` and in `LoadBalances`); one `InvalidAmount` subclass per form (four classes for one error) |
| D22 | The seven error classes have no spec file of their own: each message is checked, with its class, in the spec of the class that raises it (the `AccountNumber`, `Money`, `Transfer`, `Account`, `AccountRepository` and `TransferService` specs) | DEC-34 | DEC-34 says one spec file per class and that each rule is tested once, where it belongs; an error class holds no rule of its own, only the wording of its message, and that wording is the observable result of the rule that raises it, so a separate file would test it twice | A `spec/domain/errors_spec.rb` |
| D23 | `AccountNumber` members: `AccountNumber.new(text)` (or `text:`), a `Data` record with the one member `text`; `to_s` gives the same full text; `==`, `eql?` and `hash` come from `Data` and compare by text | page 6 `AccountNumber` (a value that compares equal, with its full text for the report and the output file), brief rule 5, DEC-30 (P34) | `to_s` is what string interpolation in messages, the report and the output file call; `Data` gives equality, `hash` and freezing with nothing written by hand, so it works as the repository's `Hash` key | `==`, `eql?`, `hash` and `freeze` written by hand (more code for the same behaviour); `to_str` (implicit conversion hides mistakes) |
| D24 | `Account#withdraw` and `#deposit` first call one private check that raises `ArgumentError` with `amount <amount> must be greater than 0.00` for an amount of $0 or less; `withdraw` works out `balance - money` once and reuses it | DEC-18, DEC-30, FR-012 (P33); page 10 pick 56 | A programming error gets Ruby's own error class, as in D10; one check for both methods | A domain error class; a check repeated in each method |
| D25 | A `Data` record is written as `Name = Data.define(...) do ... end`, with its check in `initialize` before `super` and its constants set after the block (`AccountNumber::PATTERN`) | DEC-30 (P34); page 10 pick 57 | The form of `Row` and `DayResult` in `002`; a constant set inside the block would belong to the top level | `class Name < Data.define(...)` (RuboCop's `Style/DataInheritance`); reopening the class |

## Complexity Tracking

No violation of the constitution; nothing to justify.

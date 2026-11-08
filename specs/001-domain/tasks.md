# Tasks: Domain and project skeleton

**Input**: Design documents from `specs/001-domain/`: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/domain-api.md](contracts/domain-api.md), [quickstart.md](quickstart.md). The `/speckit-tasks` input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#speckit-tasks-001-domain).

**Prerequisites**: none; this is the first spec. `002-file-runner` starts from the end of this one.

**Tests**: required. Tests come first in every phase (constitution IV, [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34)): write the spec, run it and see the new examples fail, then write the code until they pass. Every phase ends with `bundle exec rspec` passing in random order and `bundle exec rubocop` reporting zero offences. This spec tests the domain directly (brief rule 4): the result, the error class and its exact message, and that no balance changes after every refusal. The run outcomes in the spec are run by `002`, not here.

**Organization**: phases follow the order the code depends on, not the priority order: values (US4), then money arithmetic (US6), the account (US2), the repository (US5, US3), and the transfer service and results (US1). Each phase is still one user story, tested on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task).
- **[Story]**: the user story in [spec.md](spec.md) the task belongs to.
- IDs in brackets after a task name the requirement (FR-0nn in the spec, FR-nn and NFR-nn on pages 2 and 3), the acceptance scenario (AC-nn.n), the decision (DEC-nn) and the plan's decided-in-the-run item (Dnn) it serves.

## Conventions for every spec task

- Each spec file starts with `# frozen_string_literal: true`, requires the class under test with `require 'domain/<file>'`, and has one top-level `RSpec.describe <Class>` (D13, D16).
- One expectation per example; balances are compared as one array of strings, for example `expect(repository.all.map { |a| a.balance.to_s }).to eq(%w[100.00 50.00 0.00])` (D17).
- A refusal is checked in two examples: one for the error class and its exact message, `expect { ... }.to raise_error(InsufficientFunds, 'account 1111234522226789 cannot pay 100.01 from a balance of 100.00')`, and one for the unchanged balances after `attempt(InsufficientFunds) { ... }` (D17, D18).
- Messages are copied character for character from the [spec's message table](spec.md#domain-error-messages) (FR-027, SC-004).
- Table rows become one example each, generated from a list in the spec file, so the example names read as the rule (for example `rejects "1e3" as not a valid amount`).
- An example that proves an edge case names its DEC ID in its description, for example `applies a transfer that leaves exactly 0.00 (DEC-13)`.
- The three accounts of the spec's `balances.csv` are `1111234522226789` 100.00, `1212343433335665` 50.00 and `0000123412341234` 0.00, added in that order.

---

## Phase 1: Setup (project skeleton; delivers User Story 7)

**Purpose**: the frame every later test runs in (NFR-05; DEC-01, DEC-27, DEC-30, DEC-34, DEC-36). Nothing here has behaviour of its own to test with RSpec; the checkpoint runs the tools.

- [X] T001 Create `.ruby-version` containing `3.4.12` and a final newline [FR-036; DEC-01; D1; research R1]
- [X] T002 Create `Gemfile`: `# frozen_string_literal: true`, `source 'https://rubygems.org'`, then `gem 'bigdecimal'`, `gem 'csv'`, `gem 'logger'` at top level, then `group :development, :test do` with `gem 'rspec'`, `gem 'rubocop'`, `gem 'rubocop-rspec'`, `gem 'simplecov'`; no version constraints and no `ruby` line [FR-037; DEC-01, DEC-36; D14; research R2]
- [X] T003 Run `bundle install`, then `bundle lock --add-platform x86_64-linux x64-mingw-ucrt`, and keep the resulting `Gemfile.lock` for commit; `003` later completes its `PLATFORMS` list, so do not add more here [FR-037; DEC-01; D14; research R2]
- [X] T004 [P] Create `.rspec` with the two lines `--require spec_helper` and `--format documentation` [FR-039; DEC-34; D13; research R11]
- [X] T005 [P] Create `.rubocop.yml` containing only `plugins:` with the one item `- rubocop-rspec` [FR-031; DEC-36; D15; research R3]
- [X] T006 [P] Create `.gitignore` with the lines `coverage/` and `output/` [FR-041; DEC-27, DEC-36]
- [X] T007 [P] Create `spec/support/builders.rb`: `# frozen_string_literal: true`, a one-line comment saying it holds the test builders, and an empty `module Builders` that later phases fill [FR-038; DEC-34; D16; research R10]
- [X] T008 Create `spec/spec_helper.rb`, in this order: `require 'simplecov'` and `SimpleCov.start { add_filter '/spec/' }`; `$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))`; require every file in `spec/support/` (sorted); `RSpec.configure` with `expect_with` using the `expect` syntax only, `disable_monkey_patching!`, `order = :random`, `Kernel.srand config.seed`, and `include Builders` (depends on T007) [FR-039, FR-040; DEC-34, DEC-36; D13, D20; research R11]
- [X] T009 Run `bundle exec rspec` (0 examples, `Randomized with seed <n>` printed, `coverage/` written) and `bundle exec rubocop` (`no offenses detected`) to confirm `.rspec`, `spec/spec_helper.rb`, `spec/support/builders.rb` and `.rubocop.yml` work together; `lib/domain/` and `spec/domain/` are created by the first tasks that write into them (T010, T016), and nothing is created under `lib/application/` or `lib/infrastructure/` in this spec (depends on T001 to T008) [US7 scenarios 2, 3; FR-031, FR-038 to FR-040; DEC-30, DEC-34, DEC-36]

**Checkpoint (US7 scenarios 1 to 4)**: `bundle install` uses the committed lock and leaves it unchanged; `bundle exec rspec` runs (0 examples, `Randomized with seed <n>` printed) and writes `coverage/`; `bundle exec rubocop` reports `no offenses detected`; `git status --short` lists nothing under `coverage/`.

---

## Phase 2: Foundational

No shared code blocks the stories beyond Phase 1. Each domain error is added to `lib/domain/errors.rb` in the phase whose test first raises it, and each builder in the phase that first uses it, so that no code is written before its test.

---

## Phase 3: User Story 4 - Only valid account numbers and exact money values are accepted (Priority: P1)

**Goal**: `AccountNumber`, the `Money` format and written form, the `Transfer` checks and the opening-balance check (FR-06; DEC-08, DEC-09, DEC-10, DEC-11, DEC-19).

**Independent Test**: build `AccountNumber`, `Money`, `Transfer` and the opening-balance check from each value in AC-06.1 to AC-06.3 and check the value, or the error class and its exact message.

### Tests for User Story 4 (write first)

- [X] T010 [P] [US4] Write `spec/domain/account_number_spec.rb` [FR-001, FR-002; AC-06.1; DEC-08; research R4]:
  - valid: `1111234522226789` gives `to_s` `1111234522226789`;
  - leading zeros kept: `0000123412341234` gives `to_s` `0000123412341234` (DEC-08);
  - equal to another `AccountNumber` built from the same text, and not equal to one built from other text;
  - usable as the same `Hash` key: a `Hash` keyed by `AccountNumber.new('0000123412341234')` finds the value with a second `AccountNumber.new('0000123412341234')` (`eql?` and `hash`);
  - no check digit: each of the five sample numbers `1111234522226789`, `1111234522221234`, `2222123433331212`, `1212343433335665`, `3212343433335755` is valid (DEC-08);
  - invalid, each raising `InvalidAccountNumber` with `account number "<text>" must be exactly 16 digits`: `111123452222678` (15 digits), `11112345222267890` (17 digits), `1111O34522226789` (letter O), `1111-2345-2222-6789` (dashes), `12345`, and the empty text, giving `account number "" must be exactly 16 digits` (DEC-08).
- [X] T011 [P] [US4] Write `spec/domain/money_spec.rb`, parsing, writing, equality and comparison [FR-003 to FR-007; AC-06.2, AC-06.3; DEC-09, DEC-10; D4, D5; research R5 to R7]:
  - valid and written with 2 decimals by `to_s`: `Money.amount('10')` `10.00`, `'10.5'` `10.50`, `'10.50'` `10.50`, `'007.50'` `7.50` (DEC-09), `'550'` `550.00`, `'5000.00'` `5000.00`, `'0'` `0.00`, `'0.00'` `0.00`;
  - `text` returns the text as written: `Money.amount('007.50').text` is `007.50`; for a computed value it is the same as `to_s` (see T021);
  - not negative: `0`, `0.00`, `10.00`; negative: `-5.00`, `-0`, `-0.00` (`negative?`; DEC-09);
  - `positive?`: true for `0.01` and `10.00`; false for `0`, `0.00`, `-0`, `-0.00`, `-5.00`;
  - equality by amount only: `Money.amount('-0')` and `Money.amount('-0.00')` each equal `Money.amount('0')`; `Money.amount('10.5')` equals `Money.amount('10.50')`; equal values have equal `hash`, and `Money.amount('-0').hash` equals `Money.amount('0').hash` (spec clarification 2);
  - comparison: `Money.amount('10.00') < Money.amount('10.01')` and `Money.amount('100.00') > Money.amount('99.99')`;
  - more than 2 decimal places, never rounded: `Money.amount('1.234')` raises `InvalidAmount`, `amount "1.234" has more than 2 decimal places`; `Money.amount('-1.234')` raises `amount "-1.234" has more than 2 decimal places` (DEC-09);
  - empty: `Money.amount('')` raises `amount is empty`;
  - not a valid amount, each raising `amount "<text>" is not a valid amount`: `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0`, `1,000.00` (DEC-09);
  - DEC-09's own examples: `100`, `100.5` and `100.50` are valid and written `100.00`, `100.50`, `100.50`; `100.`, `+100` and `$100` are not a valid amount;
  - the `balance` word: `Money.balance('1.234')` raises `balance "1.234" has more than 2 decimal places`; `Money.balance('abc')` raises `balance "abc" is not a valid amount`; `Money.balance('')` raises `balance is empty` (spec item 2; AC-06.3).
- [X] T012 [P] [US4] Write `spec/domain/transfer_spec.rb` [FR-008, FR-009; AC-03.3, AC-06.2; DEC-10, DEC-13, DEC-19; D8]:
  - a valid transfer from `1111234522226789` to `1212343433335665` of `30.00` returns those values from `from`, `to` and `amount`;
  - `0.01` is accepted (DEC-10);
  - an amount of $0 or less, each raising `InvalidAmount` with `amount "<text>" must be greater than 0.00`: `0`, `0.00`, `-5.00`, `-0`, `-0.00` (DEC-10; `-0` and `-0.00` per DEC-09);
  - the same account: from and to `9999888877776666`, amount `5.00`, raises `SameAccount`, `account 9999888877776666 cannot transfer to itself`, with no repository involved, so an account that is not loaded still gets `SameAccount` (DEC-19 edge case);
  - check order: from and to `1111234522226789`, amount `0`, raises `InvalidAmount` with `amount "0" must be greater than 0.00`, not `SameAccount` (DEC-19 edge case).
- [X] T013 [P] [US4] Write `spec/domain/account_spec.rb`, the opening balance only [FR-013; AC-06.3; DEC-10, DEC-11; D6, D7]:
  - `Account.check_opening_balance` accepts `Money.balance('0')`, `'0.00'`, `'5000.00'` and `'550'` without raising (DEC-10);
  - it raises `NegativeBalance` for `-5.00`, `-0` and `-0.00`, with `balance "-5.00" must not be negative`, `balance "-0" must not be negative` and `balance "-0.00" must not be negative` (DEC-09, DEC-11);
  - it needs only the `Money`: it is called with no `AccountNumber` at all (page 6 `Account`);
  - `Account.new(account_number('1111234522226789'), Money.balance('-5.00'))` raises the same `NegativeBalance`;
  - `Account.new` with `100.00` gives `number.to_s` `1111234522226789` and `balance.to_s` `100.00`.
- [X] T014 [P] [US4] Add to `spec/support/builders.rb` the builders `account_number(text = '1111234522226789')`, `amount(text = '10.00')` (`Money.amount`) and `balance(text = '100.00')` (`Money.balance`), each requiring the class it builds [DEC-34; research R10]
- [X] T015 [US4] Run `bundle exec rspec` and confirm every example from T010 to T013 fails because the classes do not exist yet (depends on T010 to T014)

### Implementation for User Story 4

- [X] T016 [US4] Create `lib/domain/errors.rb` with a one-line comment per class and `InvalidAccountNumber` (built with `new(text)`, message `account number "<text>" must be exactly 16 digits`), `InvalidAmount` (raised with its full message), `SameAccount` (built with `new(account_number)`, message `account <number> cannot transfer to itself`) and `NegativeBalance` (built with `new(balance)`, message `balance "<balance.text>" must not be negative`), each a direct subclass of `StandardError` [FR-026, FR-027; DEC-30; D3, D21]
- [X] T017 [P] [US4] Create `lib/domain/account_number.rb`: `AccountNumber.new(text)` raises `InvalidAccountNumber` unless `text` matches `/\A[0-9]{16}\z/`; `to_s`, `==`, `eql?` and `hash` by text; frozen [FR-001, FR-002; DEC-08; D19; research R4]
- [X] T018 [P] [US4] Create `lib/domain/money.rb`: `Money.amount(text)` and `Money.balance(text)` classify the text in the order of research R5 (empty; `/\A-?[0-9]+\.[0-9]{3,}\z/`; not `/\A-?[0-9]+(\.[0-9]{1,2})?\z/`) and raise `InvalidAmount` with the label `amount` or `balance`, else build `Money.new(BigDecimal(text), text)`; `text` (the written text when one was given, `to_s` otherwise), `to_s` (research R6, no `Float`, no rounding), `negative?` (a written `-`, checked only when there is written text, or value below 0), `positive?`, `Comparable` with `<=>`, `==`, `eql?` and `hash` by value, with `hash` defined as `value.zero? ? BigDecimal('0').hash : value.hash` so that `-0` and `0` hash alike; frozen [FR-003 to FR-007; DEC-09; D4, D5, D19; research R5 to R7]
- [X] T019 [US4] Create `lib/domain/transfer.rb`: `Transfer.new(from:, to:, amount:)` raises `InvalidAmount` with `amount "<amount.text>" must be greater than 0.00` unless `amount.positive?`, then `SameAccount.new(from)` when `from == to`; readers `from`, `to`, `amount`; frozen (depends on T016 to T018) [FR-008, FR-009; DEC-10, DEC-13, DEC-19; D8, D19]
- [X] T020 [US4] Create `lib/domain/account.rb` with `Account.check_opening_balance(balance)` (raises `NegativeBalance.new(balance)` when `balance.negative?`), `Account.new(number, balance)` calling it, and the readers `number` and `balance` (depends on T016, T018) [FR-010, FR-013; DEC-10, DEC-11; D6, D7]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences. Every row of AC-06.1, AC-06.2 (domain outcomes) and AC-06.3 is green.

---

## Phase 4: User Story 6 - Money stays exact to the cent (Priority: P2)

**Goal**: exact adding, taking away and comparing of `Money`, with no upper limit (NFR-01; DEC-09). Needed by `Account#withdraw` and `#deposit` in Phase 5.

**Independent Test**: add and take away `Money` values many times and compare with the exact expected value.

### Tests for User Story 6 (write first)

- [X] T021 [US6] Add to `spec/domain/money_spec.rb` a `describe` for arithmetic [FR-006; US6 scenarios 1 to 3; NFR-01; DEC-09; research R7]:
  - `0.10` plus `0.20` is exactly `0.30` (`to_s`);
  - from `0.00`, adding `25.60` 1,000 times gives exactly `25600.00` (page 10 pick 21);
  - from `0.00`, adding `25.60` 1,000 times and then taking it away 1,000 times gives exactly `0.00`;
  - no upper limit: `123456789012345678901234567890.12` plus `0.01` is written `123456789012345678901234567890.13` (DEC-09);
  - `5.00` minus `5.00` is `0.00` and not `negative?` (spec clarification 2);
  - `5.00` minus `5.01` is `negative?` and written `-0.01`;
  - a computed value has `text` equal to `to_s`: `(Money.amount('5.00') + Money.amount('2.50')).text` is `7.50`.
- [X] T022 [US6] Run `bundle exec rspec spec/domain/money_spec.rb` and confirm the new examples fail (no `+` or `-` yet) (depends on T021)

### Implementation for User Story 6

- [X] T023 [US6] Add `+` and `-` to `lib/domain/money.rb`, each returning `Money.new(value ± other.value)` with no written text (its `text` is then `to_s`), so the result is negative only below 0 (depends on T022) [FR-006; NFR-01; DEC-09; D5]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 5: User Story 2 - No balance ever goes below $0, and exactly $0 is allowed (Priority: P1)

**Goal**: `Account#withdraw` and `Account#deposit` (FR-04; DEC-10, DEC-13, DEC-18). The same scenarios through `TransferService` are tested in Phase 8, where the service is built.

**Independent Test**: build an `Account` and call `withdraw` with amounts just below, at and above its balance.

### Tests for User Story 2 (write first)

- [X] T024 [US2] Add `attempt(error_class)` to `spec/support/builders.rb`: it yields, rescues only `error_class` and returns nil [D17; research R10]
- [X] T025 [US2] Add to `spec/domain/account_spec.rb` a `describe '#withdraw'` and a `describe '#deposit'` [FR-010 to FR-012; AC-04.1 to AC-04.3; DEC-10, DEC-13, DEC-18; D17]:
  - an account `1111234522226789` holding `100.00`: `withdraw(amount('30.00'))` leaves `70.00`;
  - exactly $0: `withdraw(amount('100.00'))` leaves `0.00` and raises nothing (DEC-13 edge case; AC-04.2);
  - one cent below $0: `withdraw(amount('100.01'))` raises `InsufficientFunds`, `account 1111234522226789 cannot pay 100.01 from a balance of 100.00` (DEC-13 edge case; AC-04.1);
  - after that refused withdrawal (`attempt(InsufficientFunds)`), the balance is still `100.00` (DEC-18);
  - an account `0000123412341234` holding `0.00`: `withdraw(amount('0.01'))` raises `InsufficientFunds`, `account 0000123412341234 cannot pay 0.01 from a balance of 0.00` (DEC-10; AC-04.3);
  - the message writes both values with 2 decimals: an account holding `5` refusing `007.50` gives `account 1111234522226789 cannot pay 7.50 from a balance of 5.00`;
  - `deposit(amount('30.00'))` on `0.00` leaves `30.00`.
- [X] T026 [US2] Add the builder `account(number = '1111234522226789', opening = '100.00')` to `spec/support/builders.rb`, building `Account.new(account_number(number), balance(opening))` [DEC-34; research R10]
- [X] T027 [US2] Run `bundle exec rspec spec/domain/account_spec.rb` and confirm the new examples fail (depends on T024 to T026)

### Implementation for User Story 2

- [ ] T028 [US2] Add `InsufficientFunds` to `lib/domain/errors.rb`, built with `new(account_number, amount, balance)` and the message `account <number> cannot pay <amount.to_s> from a balance of <balance.to_s>` [FR-011, FR-027; DEC-13; D21]
- [ ] T029 [US2] Add `withdraw(money)` to `lib/domain/account.rb`: raise `InsufficientFunds` when `(balance - money).negative?`, before changing anything; otherwise set the balance to `balance - money`. Add `deposit(money)`: set the balance to `balance + money`. Neither checks that the amount is above $0 (depends on T028) [FR-010 to FR-012; DEC-13, DEC-18; spec clarification 3]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 6: User Story 5 - The repository keeps the accounts, one per number, in load order (Priority: P2)

**Goal**: `AccountRepository#add`, `#include?`, `#find` for a held number, and `#all` (supports FR-01; NFR-02; DEC-11, DEC-12, DEC-31).

**Independent Test**: add accounts to an empty `AccountRepository` and call `include?`, `find`, `add` and `all`.

### Tests for User Story 5 (write first)

- [ ] T030 [US5] Write `spec/domain/account_repository_spec.rb` [FR-014, FR-015, FR-017, FR-018; US5 scenarios 1 to 4; DEC-11, DEC-12, DEC-31]:
  - a new repository's `all` is empty;
  - accounts `1111234522226789`, `1212343433335665` and `0000123412341234` added in that order come back from `all` in that order (DEC-31);
  - `include?(account_number('1111234522226789'))` is true when that account is held; `include?(account_number('9999888877776666'))` is false (DEC-12);
  - `include?` with a different `AccountNumber` object built from the same text is true;
  - adding a second account `1111234522226789` with the same balance raises `DuplicateAccount`, `account 1111234522226789 appears more than once` (DEC-11 edge case);
  - adding it with a different balance (`999.00`) raises the same `DuplicateAccount` (DEC-11 edge case);
  - after the refused duplicate (`attempt(DuplicateAccount)`), `all` holds one account with the first balance, `100.00` (DEC-31);
  - `find(account_number('1111234522226789'))` returns the same `Account` object that was added (`equal?`);
  - a withdrawal made on the account returned by `find` is seen in `all` (`find(...).withdraw(amount('30.00'))`, then the balance in `all` is `70.00`).
- [ ] T031 [US5] Add the builder `repository_with(*accounts)` to `spec/support/builders.rb`, returning an `AccountRepository` with each account added in order [DEC-34; research R10]
- [ ] T032 [US5] Run `bundle exec rspec spec/domain/account_repository_spec.rb` and confirm the examples fail (depends on T030, T031)

### Implementation for User Story 5

- [ ] T033 [US5] Add `DuplicateAccount` to `lib/domain/errors.rb`, built with `new(account_number)` and the message `account <number> appears more than once` [FR-014, FR-027; DEC-31; D21]
- [ ] T034 [US5] Create `lib/domain/account_repository.rb`: one `Hash` keyed by `account.number.to_s`; `add(account)` raises `DuplicateAccount.new(account.number)` when the key is held, else stores the account; `include?(account_number)` is `key?(account_number.to_s)`; `find(account_number)` returns the held account; `all` returns the `Hash`'s values (depends on T033) [FR-014 to FR-018, FR-033, FR-035; NFR-02; DEC-31; research R8]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 7: User Story 3 - A transfer naming an account that is not loaded is refused (Priority: P2)

**Goal**: `AccountRepository#find` raises `UnknownAccount` for a number it does not hold and never creates an account (FR-05; DEC-17, DEC-31). The scenarios through `TransferService` (AC-05.1, AC-05.2, both unknown) are tested in Phase 8.

**Independent Test**: call `AccountRepository#find` with a number it does not hold, then check `include?` and `all`.

### Tests for User Story 3 (write first)

- [ ] T035 [US3] Add to `spec/domain/account_repository_spec.rb` a `describe '#find'` context for a number not held [FR-016; US3 scenario 4; DEC-17, DEC-31]:
  - on a repository holding the three accounts, `find(account_number('9999888877776666'))` raises `UnknownAccount`, `account 9999888877776666 is not loaded` (DEC-17);
  - on an empty repository, after the refused `find` (`attempt(UnknownAccount)`), `include?` for `9999888877776666` is false (DEC-17 edge case: never creates);
  - on an empty repository, after the refused `find`, `all` is empty (DEC-31).
- [ ] T036 [US3] Run `bundle exec rspec spec/domain/account_repository_spec.rb` and confirm the new examples fail (depends on T035)

### Implementation for User Story 3

- [ ] T037 [US3] Add `UnknownAccount` to `lib/domain/errors.rb`, built with `new(account_number)` and the message `account <number> is not loaded` [FR-016, FR-027; DEC-17; D21]
- [ ] T038 [US3] Change `find` in `lib/domain/account_repository.rb` to `fetch` with a block that raises `UnknownAccount.new(account_number)` (depends on T037) [FR-016; DEC-17, DEC-31; research R8]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 8: User Story 1 - A valid transfer moves the money, all or nothing (Priority: P1) MVP

**Goal**: `TransferService` and `TransferResult` (FR-03; DEC-13, DEC-14, DEC-16, DEC-18, DEC-19). With this phase every domain outcome in the spec is covered, including the service-level views of AC-04.1 to AC-04.3, AC-05.1, AC-05.2, US3 scenario 3 and US6 scenario 4, which need the service.

**Independent Test**: build the three accounts in a repository, apply transfers through `TransferService`, and check the balances and the errors raised; build `TransferResult`s and check what they return.

### Tests for User Story 1 (write first)

- [ ] T039 [P] [US1] Add the builder `transfer(from: '1111234522226789', to: '1212343433335665', amount: '30.00')` to `spec/support/builders.rb`, taking text and building `Transfer.new` with `account_number` and `amount`; and the helper `three_accounts`, returning `repository_with` the three accounts of the spec's `balances.csv` [DEC-34; research R10]
- [ ] T040 [P] [US1] Write `spec/domain/transfer_service_spec.rb`, every example on `three_accounts` unless it says otherwise, comparing the balances of `all` as one array [FR-019 to FR-021, FR-034; AC-03.1 to AC-03.3, AC-04.1 to AC-04.3, AC-05.1, AC-05.2, US3 scenario 3, US1 scenario 4, US6 scenario 4; SC-002]:
  - applied: `1111234522226789` to `1212343433335665` `30.00` gives `70.00 80.00 0.00` (AC-03.1; DEC-13);
  - `apply` returns nil (D12);
  - exactly $0: `1111234522226789` to `1212343433335665` `100.00` gives `0.00 150.00 0.00` (AC-04.2; DEC-13 edge case);
  - below $0 by one cent: `100.01` raises `InsufficientFunds`, checked by its class only; the message is checked in T025 (AC-04.1; DEC-13 edge case);
  - after that refusal, the balances are `100.00 50.00 0.00`, so nothing was deposited (AC-04.1; DEC-18; D18);
  - an account at $0.00: `0000123412341234` to `1111234522226789` `0.01` leaves the balances unchanged after `attempt(InsufficientFunds)`; the refusal and its message are tested in T025 (AC-04.3; DEC-18);
  - unknown to account: `1111234522226789` to `9999888877776666` `10.00` raises `UnknownAccount`, checked by its class only; the message is checked in T035 (AC-05.1; DEC-17);
  - after that refusal, the balances are unchanged, so nothing was withdrawn (AC-05.1; DEC-18 edge case; D18);
  - after that refusal, `all` holds only the three loaded account numbers (AC-05.1; DEC-17);
  - unknown from account: `9999888877776666` to `1111234522226789` `10.00` raises `UnknownAccount` and the balances are unchanged afterwards (AC-05.2; DEC-17, DEC-18);
  - both unknown: `9999888877776666` to `8888777766665555` `10.00` raises `UnknownAccount` that names the from account, checked with `raise_error(UnknownAccount, /9999888877776666/)`, which proves the from account is looked up first (US3 scenario 3; DEC-17 edge case; spec item 10);
  - unknown to account and too much money: `1111234522226789` to `9999888877776666` `1000000.00` raises `UnknownAccount`, not `InsufficientFunds`, because both lookups come before the withdrawal (AC-03.3; DEC-18, DEC-19 edge case);
  - refused while building the transfer: after `attempt(InvalidAmount) { service.apply(transfer(amount: '0')) }` the balances are unchanged, after `attempt(SameAccount) { service.apply(transfer(to: '1111234522226789')) }` the balances are unchanged, and after `attempt(InvalidAccountNumber) { service.apply(transfer(from: '12345')) }` the balances are `100.00 50.00 0.00` (AC-03.2; DEC-18 edge case);
  - the total stays the same after every refusal: after one refused transfer of each of `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `UnknownAccount` and `InsufficientFunds`, the balances add up to `150.00` (AC-03.2; SC-002);
  - after a refusal, the next transfer is applied: a refused `100.01` followed by `30.00` gives `70.00 80.00 0.00` (AC-03.2; DEC-14);
  - two equal transfers are both applied: `1111234522226789` to `0000123412341234` `20.00` twice gives `60.00 50.00 40.00` (US1 scenario 4; DEC-16 edge case);
  - the sample transfers on the five sample accounts (`1111234522226789` 5000.00, `1111234522221234` 10000.00, `2222123433331212` 550.00, `1212343433335665` 1200.00, `3212343433335755` 50000.00), applied in order (`1111234522226789` to `1212343433335665` `500.00`; `3212343433335755` to `2222123433331212` `1000.00`; `3212343433335755` to `1111234522226789` `320.50`; `1111234522221234` to `1212343433335665` `25.60`) give exactly `4820.50 9974.40 1550.00 1725.60 48679.50` (US6 scenario 4; DEC-35; NFR-01);
  - the same sample run keeps the total at `66750.00` (US6 scenario 4; DEC-35; SC-003).
- [ ] T041 [P] [US1] Write `spec/domain/transfer_result_spec.rb` [FR-022 to FR-025; US1 scenario 5; DEC-06, DEC-19; D9 to D11]:
  - `REASON_CODES` is `%i[malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds]`, in that order (DEC-19; spec item 11);
  - `applied(line_number: 1, fields: %w[1111234522226789 1212343433335665 30.00])` is `applied?`, not `rejected?`, and has no `reason` and no `header_hint`;
  - it returns `line_number` `1` and the three `fields` unchanged, in order;
  - `rejected(..., reason: :insufficient_funds)` is `rejected?`, not `applied?`, with `reason` `:insufficient_funds`;
  - each of the six reason codes is accepted by `rejected` (one example per code);
  - a reason outside the list (`:overdrawn`) raises `ArgumentError` (D10);
  - a header hint is kept: `rejected(line_number: 1, fields: %w[from to amount], reason: :invalid_account_number, header_hint: 'This looks like a header row; files must not have a header.')` returns that `header_hint` (DEC-06; FR-023);
  - a rejected result without a header hint has `header_hint` nil;
  - `malformed_row` keeps fewer than 3 fields: line 4 with `%w[1111234522226789 1212343433335665]` returns both fields, in that order, so `fields.size` is 2 (DEC-19 edge case; page 2 AC-02.1);
  - `malformed_row` keeps more than 3 fields: a row of 4 fields returns all 4 (DEC-19 edge case);
  - the fields cannot be changed through the result: `fields` is frozen (D19);
  - values are kept as written: an empty amount `''` and `10.` are returned as `''` and `10.` (FR-022).
- [ ] T042 [US1] Run `bundle exec rspec spec/domain/transfer_service_spec.rb spec/domain/transfer_result_spec.rb` and confirm the examples fail (depends on T039 to T041)

### Implementation for User Story 1

- [ ] T043 [P] [US1] Create `lib/domain/transfer_result.rb`: `REASON_CODES` (frozen, symbols, DEC-19 order); `TransferResult.applied(line_number:, fields:)`; `TransferResult.rejected(line_number:, fields:, reason:, header_hint: nil)` raising `ArgumentError` for a reason not in `REASON_CODES`; readers `line_number`, `fields` (a frozen copy), `reason`, `header_hint`; `applied?` and `rejected?`; frozen; no formatting method [FR-022 to FR-025; DEC-19; D9 to D11, D19]
- [ ] T044 [P] [US1] Create `lib/domain/transfer_service.rb`: `TransferService.new(repository)`; `apply(transfer)` finds the from account, then the to account, then calls `withdraw(transfer.amount)` on the from account and `deposit(transfer.amount)` on the to account, and returns nil; no rescue, no logging, no undo [FR-019 to FR-021, FR-034; DEC-13, DEC-17, DEC-18; D12; research R9]

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences. Every domain outcome in the spec's acceptance scenarios now has a passing test (SC-001).

---

## Phase 9: Polish and cross-cutting checks

**Purpose**: prove the measurable outcomes and the design review targets (NFR-02, NFR-05; SC-001 to SC-008).

- [ ] T045 Run `bundle exec rspec` three times and confirm it passes with three different seeds; rerun one with `--seed <n>` (SC-008; DEC-34)
- [ ] T046 Run `bundle exec rubocop` and confirm `no offenses detected`; confirm no method in `lib/domain/` is longer than 10 lines (SC-005; NFR-05; DEC-36)
- [ ] T047 Check every expected message in `spec/domain/` against the [spec's message table](spec.md#domain-error-messages), 10 of 10 rows, character for character (SC-004; FR-027)
- [ ] T048 Design review of `lib/domain/` against [data-model.md](data-model.md#one-home-per-rule-fr-028-nfr-05): each of the 8 rules is in exactly one class; no file reads a file, prints, logs, reads the clock or mentions a line number; no comment explains the design; no base class, suffix, factory, DTO or mapper (SC-006; FR-028 to FR-030, FR-032; DEC-30)
- [ ] T049 Design review of cost against the [time and space table](../../docs/solution-design/09-considerations.md#time-and-space): `add`, `include?` and `find` use only `Hash` key operations; `all` returns the values once; `apply` makes two lookups and two balance changes (SC-007; FR-033 to FR-035; NFR-02)
- [ ] T050 Run every step of [quickstart.md](quickstart.md) and confirm each expected outcome, including `git status --short` showing no `coverage/` and `git ls-files lib spec` listing only the files in the plan (US7 scenarios 1 to 4; FR-036 to FR-042)
- [ ] T051 Confirm no file was created under `lib/application/`, `lib/infrastructure/`, `bin/`, `data/`, `spec/application/`, `spec/infrastructure/`, `spec/acceptance/` or `spec/fixtures/`; those belong to `002` (FR-038; brief rule 3)

---

## Edge cases and their tests

Every edge case in the [spec](spec.md#edge-cases) that falls in this spec's scope, with the task whose test proves it.

| Edge case | DEC | Test in |
|---|---|---|
| A transfer that leaves exactly $0.00 is applied; one cent more is refused | DEC-13 | T025 (`Account`, once, with the message); T040 proves only the unchanged balances at service level |
| A rejected transfer leaves both balances unchanged, for `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `UnknownAccount` and `InsufficientFunds` | DEC-18 | T040 |
| A known from account without enough money and an unknown to account gets `UnknownAccount` | DEC-18, DEC-19 | T040 |
| A transfer to itself with an amount of 0 gets `InvalidAmount` | DEC-19 | T012 |
| A transfer to itself that is not loaded gets `SameAccount` | DEC-19 | T012 |
| Both accounts unknown: `UnknownAccount` names the from account | DEC-17 | T040 (lookup order; the message form is tested in T035) |
| `-0` and `-0.00` are negative: refused as an amount and as an opening balance; equal to `0` as `Money` | DEC-09 | T012, T013, T011 |
| A computed `Money` is negative only below 0 | DEC-09 | T021 |
| A `malformed_row` result keeps every field, fewer or more than 3 | DEC-19 | T041 |
| `0` and `0.00` are a valid opening balance but not a valid transfer amount | DEC-10 | T013, T012 |
| `007.50` is valid, written `7.50`; `10.` and `.50` are invalid | DEC-09 | T011 |
| `+100`, `1e3`, `$100`, `1,000.00` and values with spaces inside are invalid | DEC-09 | T011 (`+100`, `$100`, `+10`, `1e3`, `$10`, `1,000.00`, `1 0`) |
| More than 2 decimal places is refused, never rounded, including `-1.234` | DEC-09 | T011 |
| Leading zeros are kept, and equal another built from the same text | DEC-08 | T010 |
| 15 or 17 digits, a letter, dashes, or empty is invalid | DEC-08 | T010 |
| A duplicate is refused whether its balance is the same or different, and the first is kept | DEC-11, DEC-31 | T030 |
| `find` for a number not held raises and never adds an account | DEC-17, DEC-31 | T035 |
| Two equal transfers are both applied | DEC-16 | T040 |
| A very large amount stays exact | DEC-09 | T021 |
| No check-digit check: all five sample numbers are valid | DEC-08 | T010 |
| The sample transfers give exactly the DEC-35 balances, total 66750.00 | DEC-35 | T040 |

Edge cases owned by `002` and not tested here: blank lines, header rows and the byte-order mark (DEC-04 to DEC-06), line numbers (DEC-07), every balances problem collected and the duplicate's first line (DEC-12), the empty transfers file and the all-rejected warning (DEC-20, DEC-21), the mapping of errors to reason codes and the order in which `ProcessDailyTransfer` builds the values (DEC-19, page 7.1), and every run outcome.

---

## Dependencies and execution order

### Phase dependencies

- **Phase 1 (Setup)**: none. Delivers US7.
- **Phase 2 (Foundational)**: nothing to do.
- **Phase 3 (US4)**: after Phase 1. Builds `AccountNumber`, `Money` (parsing), `Transfer`, `Account` (opening balance), and the first four errors.
- **Phase 4 (US6)**: after Phase 3 (`Money`).
- **Phase 5 (US2)**: after Phase 4 (`Money#+` and `#-`).
- **Phase 6 (US5)**: after Phase 5 (`Account`, `withdraw` in one example).
- **Phase 7 (US3)**: after Phase 6 (`AccountRepository`).
- **Phase 8 (US1)**: after Phases 3 to 7; it uses every class.
- **Phase 9 (Polish)**: after Phase 8.

### Within each phase

- The spec tasks come first, then the run that shows them failing, then the code.
- In Phase 3, `errors.rb` (T016) comes before the classes that raise its errors; `AccountNumber` and `Money` (T017, T018) can be written in parallel; `Transfer` and `Account` (T019, T020) need them.
- `spec/support/builders.rb` is edited by one task at a time (T014, T024, T026, T031, T039).

### Parallel opportunities

- Phase 1: T004, T005, T006, T007 in parallel, after T001 to T003.
- Phase 3: the four spec files T010 to T013 and the builders T014 in parallel; then T017 and T018 in parallel.
- Phase 8: T039, T040 and T041 in parallel; then T043 and T044 in parallel.

## Parallel example: Phase 3 (User Story 4)

```text
Task: "Write spec/domain/account_number_spec.rb (T010)"
Task: "Write spec/domain/money_spec.rb, parsing and writing (T011)"
Task: "Write spec/domain/transfer_spec.rb (T012)"
Task: "Write spec/domain/account_spec.rb, opening balance (T013)"
Task: "Add account_number, amount and balance builders (T014)"
```

## Implementation strategy

### MVP

The MVP is the end of Phase 8: one transfer applied all or nothing, with every rule behind it. The earlier phases are the values and models that User Story 1 needs, each a tested increment on its own.

### Incremental delivery

1. Phase 1: the skeleton runs RSpec and RuboCop.
2. Phase 3: account numbers and money values are validated (US4).
3. Phase 4: money adds and takes away exactly (US6).
4. Phase 5: accounts never go below $0 (US2).
5. Phases 6 and 7: the repository holds, finds and refuses accounts (US5, US3).
6. Phase 8: transfers are applied all or nothing, and each row's outcome is a `TransferResult` (US1).
7. Phase 9: the measurable outcomes and design reviews pass; `002` can start.

## Notes

- `[P]` tasks touch different files and depend on no unfinished task.
- Commit after each task or small group of tasks, naming what it covers.
- Never weaken a test or change an expected message to match the code; the messages come from the spec.
- Nothing in this spec reads a file, prints, logs or exits.

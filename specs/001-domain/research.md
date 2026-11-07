# Research: Domain and project skeleton

Phase 0 of the [plan](plan.md). The Technical Context had no open item: the language, tools and layout are fixed by [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) and [page 5](../../docs/solution-design/05-high-level-design.md). This page records how each fixed choice is applied, where Ruby or the tools need a specific technique. Each entry gives the decision, the rationale and the alternatives considered.

## R1. Ruby version

- **Decision**: Ruby 3.4.12, written in `.ruby-version` as `3.4.12` (plan D1).
- **Rationale**: DEC-01 pins "the latest 3.4.x release". The release index at `cache.ruby-lang.org/pub/ruby/index.txt` lists 3.4.12 as the highest 3.4 release on 2026-11-08. The Dockerfile (`003`) reads the same file.
- **Alternatives considered**: Ruby 4.0 (rejected by DEC-01); an older 3.4 patch (not the latest).

## R2. Gems and the lock file

- **Decision**: the `Gemfile` lists `csv`, `bigdecimal` and `logger` at top level, and `rspec`, `simplecov`, `rubocop` and `rubocop-rspec` in `group :development, :test`, with no version constraints. `bundle install` writes `Gemfile.lock`, then `bundle lock --add-platform x86_64-linux x64-mingw-ucrt` adds both platforms, and the lock is committed (plan D14).
- **Rationale**: DEC-01 commits the lock, which pins every version in one place. A lock made on one operating system lists only that platform; CI and Docker run on Linux and the developer works on Windows, so both are added and `bundle install` works everywhere from the same lock. The `Gemfile` declares no `ruby` line, so `.ruby-version` stays the one place for the version.
- **Alternatives considered**: pessimistic version constraints in the `Gemfile` (a second place for versions); a `ruby file: '.ruby-version'` line (makes every other 3.4 patch fail `bundle install`, which NFR-04 does not ask for).

## R3. RuboCop with `rubocop-rspec`

- **Decision**: `.rubocop.yml` contains only:

  ```yaml
  plugins:
    - rubocop-rspec
  ```

  RuboCop reads the target Ruby version from `.ruby-version` (plan D15).
- **Rationale**: DEC-36 asks for default settings and `rubocop-rspec`; current `rubocop-rspec` releases are loaded with `plugins:`. The defaults that shape the code are `Metrics/MethodLength` (10 lines), `Metrics/AbcSize`, `Style/Documentation` (a comment before each class), `Style/FrozenStringLiteralComment`; for specs `RSpec/MultipleExpectations` (1), `RSpec/ExampleLength` (5), `RSpec/NestedGroups` (3), `RSpec/SpecFilePathFormat` and `RSpec/DescribeClass`. Pending new cops print a notice but are not offences.
- **Alternatives considered**: `require: rubocop-rspec` (the older form, which current versions warn about); `NewCops: enable` or changed limits (not the defaults).

## R4. Account number pattern

- **Decision**: `AccountNumber` accepts text matching `/\A[0-9]{16}\z/`.
- **Rationale**: DEC-08: exactly 16 digits 0 to 9 and nothing else. `\A` and `\z` anchor the whole string (`^` and `$` would accept text around a newline); `[0-9]` states the ASCII digits outright. The text is kept as given, never turned into an integer, so leading zeros stay. No check digit.
- **Alternatives considered**: `Integer(text)` (loses leading zeros, accepts `+` and `_`); `/^\d{16}$/` (line anchors).

## R5. Parsing money text

- **Decision**: `Money` classifies the text with three patterns, in this order:
  1. empty text: `InvalidAmount`, `<label> is empty`;
  2. `/\A-?[0-9]+\.[0-9]{3,}\z/`: `InvalidAmount`, `<label> "<text>" has more than 2 decimal places`;
  3. not `/\A-?[0-9]+(\.[0-9]{1,2})?\z/`: `InvalidAmount`, `<label> "<text>" is not a valid amount`.

  Valid text becomes `BigDecimal(text)`. `<label>` is `amount` from `Money.amount` and `balance` from `Money.balance`.
- **Rationale**: DEC-09's format exactly: digits, an optional point with 1 or 2 digits, an optional leading minus. Checking more than 2 decimals before the general pattern gives the message the spec's item 4 sets (`1.234` and `-1.234` say "more than 2 decimal places"; `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0` and `1,000.00` say "is not a valid amount"). `BigDecimal` is built from the validated string, so the value never passes through a `Float`.
- **Alternatives considered**: `BigDecimal(text)` alone as the check (accepts `1e3`, `+100`, `0x1A`, surrounding spaces and underscores); `Float(text)` (inexact); rounding with `round(2)` (DEC-09 forbids it).

## R6. Writing money with 2 decimals

- **Decision**: `Money#to_s` takes `value.abs.to_s('F')` (for example `7.5`, `10.0`, `123456789012345678901234567890.13`), splits it at the point, pads the fraction to 2 digits with zeros, and puts `-` in front only when the value is below 0.
- **Rationale**: `BigDecimal#to_s('F')` is exact at any size and drops leading zeros (`007.50` gives `7.5`), so `to_s` gives `7.50`, `550.00` and `10.50` as FR-007 requires. Only values with at most 2 decimals exist, so padding never cuts digits. A negative zero (`-0`) has a value that is not below 0, so it is written `0.00`.
- **Alternatives considered**: `format('%.2f', value)` (goes through `Float` and loses exactness on large values); `value.round(2).to_s` (rounding, and the default `to_s` uses exponent notation).

## R7. Negative values and equality

- **Decision**: `Money#negative?` is true when the text as written starts with `-` or the value is below 0; `Money#positive?` is true when the value is above 0. `==`, `eql?`, `hash` and `<=>` use the value only (plan D5).
- **Rationale**: DEC-09 counts `-0` and `-0.00` as negative, but `BigDecimal('-0')` is not below 0, so the written sign must be kept (page 10 pick 25). A computed `Money` has no written text, so it is negative only below 0 (spec clarification 2). Equality by value makes `-0` equal `0` (spec item 16). `Transfer` checks `amount.positive?`, which refuses `0`, `0.00`, `-0`, `-0.00` and every negative amount with one test (FR-008).
- **Alternatives considered**: comparing the written sign in equality (rejected in the spec's clarification); `BigDecimal#sign` (still a value property; gives the same answer for `-0` only by a special constant, which is harder to read).

## R8. Repository storage

- **Decision**: `AccountRepository` keeps a `Hash` from the account number text to the `Account`. `add` uses `key?` before storing; `include?` is `key?`; `find` is `fetch` with a block that raises `UnknownAccount`; `all` is `values`.
- **Rationale**: page 10 pick 49 and NFR-02: a Ruby `Hash` gives O(1) lookups on average and keeps insertion order, so `all` returns load order with no second list. Keying by text works because `AccountNumber` is equal by text; using the text as the key keeps the `Hash` independent of `AccountNumber#hash`.
- **Alternatives considered**: an `Array` (O(m) `find`); a `Hash` plus an order list (two structures to keep in step); keying by `AccountNumber` (works, but relies on `eql?` and `hash` for no gain).

## R9. All or nothing without undo

- **Decision**: `TransferService#apply` runs `find(from)`, `find(to)`, `from_account.withdraw(amount)`, `to_account.deposit(amount)`, in that order, and rescues nothing.
- **Rationale**: DEC-18 and page 7.1: every lookup and check runs before the first change; `withdraw` compares before it changes; `deposit` cannot fail. So a refused transfer has changed nothing, and the domain error passes to the caller (`ProcessDailyTransfer` in `002`) to become a reason code.
- **Alternatives considered**: a rollback or a copy of the balances (DEC-18 rejects it; nothing can need undoing).

## R10. Test helpers

- **Decision**: `spec/support/builders.rb` defines a `Builders` module, included in every example group by `spec_helper.rb`, with builders that are valid by default: `account_number(text = '1111234522226789')`, `amount(text = '10.00')`, `balance(text = '100.00')`, `account(number = '1111234522226789', opening = '100.00')`, `transfer(from: ..., to: ..., amount: ...)` taking text, `repository_with(*accounts)`, and `attempt { ... }`, which runs the block and returns the domain error it raised (one of the seven), or nil; any other error is not rescued, so a bug still fails the test.
- **Rationale**: DEC-34: small builders that are valid by default, so each test sets only the field it is about. `attempt` lets one example check an unchanged balance after a refusal while another checks the error, keeping one expectation per example (plan D17).
- **Alternatives considered**: `FactoryBot` (another gem, ruled out by DEC-01); building every object by hand in each spec (long examples).

## R11. Spec set-up

- **Decision**: `.rspec` contains `--require spec_helper` and `--format documentation`. `spec_helper.rb`, in this order: requires and starts SimpleCov with `add_filter '/spec/'`; puts `lib/` on `$LOAD_PATH`; requires every file in `spec/support/`; configures RSpec with `config.order = :random`, `Kernel.srand config.seed`, `config.disable_monkey_patching!`, the `expect` syntax only, and `config.include Builders`.
- **Rationale**: DEC-34 (random order, documentation format) and DEC-36 (coverage on every run, no minimum). SimpleCov must start before any code is loaded to measure it. RSpec prints the seed when the order is random, so a failing order can be repeated.
- **Alternatives considered**: a `.simplecov` file (one more file); setting the order on the command line (easy to forget).

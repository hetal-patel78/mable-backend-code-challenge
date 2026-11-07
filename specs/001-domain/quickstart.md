# Quickstart: validate the domain and project skeleton

How to check that `001-domain` is done. It proves User Story 7 directly and every domain outcome in the [spec](spec.md) through the test suite. There is no `bin/run` yet; the run outcomes are checked by `002-file-runner`.

## Prerequisites

- Ruby 3.4.12, as in `.ruby-version` ([research R1](research.md#r1-ruby-version)).
- Bundler, which comes with Ruby.
- A clean checkout of the `001-domain` branch.

## Steps and expected outcomes

| # | Command, from the project root | Expected outcome | Proves |
|---|---|---|---|
| 1 | `ruby -v` | `ruby 3.4.12...` | DEC-01, FR-036 |
| 2 | `bundle install` | Installs the versions in the committed `Gemfile.lock`; the `Gemfile` names only `csv`, `bigdecimal`, `logger`, `rspec`, `simplecov`, `rubocop` and `rubocop-rspec`; `git status` shows no change to `Gemfile.lock` | US7 scenario 1; DEC-01, DEC-36, FR-037 |
| 3 | `bundle exec rspec` | Every example passes; the output lists each example as a sentence (documentation format) and prints `Randomized with seed <n>`; SimpleCov then reports that `coverage/index.html` was written; no minimum coverage fails the run | US7 scenario 2; US1 to US6; DEC-34, DEC-36, FR-039, FR-040, SC-001 to SC-004 |
| 4 | `bundle exec rspec` twice more | Passes each time with a different seed | SC-008 |
| 5 | `bundle exec rspec --seed <n>` with a seed from step 3 | Passes in the same order, so a failing order can be repeated | DEC-34 |
| 6 | `bundle exec rubocop` | `no offenses detected` | US7 scenario 3; NFR-05, FR-031, SC-005 |
| 7 | `git status --short` after steps 3 and 6 | Nothing under `coverage/` is listed; `output/` is ignored too | US7 scenario 4; FR-041 |
| 8 | `git ls-files lib spec` | Only `lib/domain/*.rb`, `spec/spec_helper.rb`, `spec/support/builders.rb` and `spec/domain/*_spec.rb`, one spec per class in [data-model.md](data-model.md) except `errors.rb` | FR-038 |

## Design review

These are checked by reading, not by a test (NFR-02, NFR-05):

- Each of the 8 rules in [data-model.md, one home per rule](data-model.md#one-home-per-rule-fr-028-nfr-05) is found in exactly one class (SC-006).
- `AccountRepository` uses one `Hash`; `add`, `include?` and `find` do no search over the accounts; `all` returns the `Hash`'s values (SC-007, FR-033 to FR-035).
- `TransferService#apply` makes two lookups, then `withdraw`, then `deposit`, and nothing else (FR-034).
- No file under `lib/domain/` reads a file, prints, logs, reads the clock or mentions a line number (FR-029); no comment explains the design (FR-032).

## Where the details are

- Members and exact messages: [contracts/domain-api.md](contracts/domain-api.md).
- Fields and rules: [data-model.md](data-model.md).
- Every test, with its scenario and DEC ID: `tasks.md`.

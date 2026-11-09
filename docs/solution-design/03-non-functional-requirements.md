# 3. Non-functional requirements

Purpose: the qualities the program must have beyond what it does (accuracy, cost, scale, portability, readability and testability), each as a measurable target with the way it is checked.

This page says only *what* each target is. How the design meets it is in [Considerations](09-considerations.md), and which component and test prove it is in [Traceability](10-traceability-glossary-assumptions.md).

The terms used below, such as RSpec, RuboCop, SimpleCov, CI, unit, integration and end-to-end tests, growth rate and design review, are defined in the [glossary](10-traceability-glossary-assumptions.md#glossary). Cost and scale are checked by design review, with no timing test, because timings depend on the machine and a day's file is small ([DEC-32](../design-analysis/design-decisions.md#dec-32)).

## Summary

| ID | Requirement | Checked by |
|---|---|---|
| [NFR-01](#nfr-01) | Money is exact to the cent | Unit tests, the sample-files end-to-end test, the total check in every run |
| [NFR-02](#nfr-02) | Cost of each operation | Design review |
| [NFR-03](#nfr-03) | Scale: file size and number of accounts | Design review |
| [NFR-04](#nfr-04) | Language version and portability | Continuous integration, a Docker run, a Windows run |
| [NFR-05](#nfr-05) | Code organisation and readability | RuboCop, design review |
| [NFR-06](#nfr-06) | Testability and coverage | The test suite, the coverage report, design review |

---

<a id="nfr-01"></a>
## NFR-01 Money accuracy

Decisions: [DEC-09](../design-analysis/design-decisions.md#dec-09), [DEC-35](../design-analysis/design-decisions.md#dec-35), [DEC-24](../design-analysis/design-decisions.md#dec-24).

**Targets**
- Every amount and balance must be exact to the cent after any number of transfers: the difference from the correct value must be $0.00, never a fraction of a cent.
- Arithmetic must be exact decimal arithmetic, never binary floating point (a number format that cannot hold values such as 25.60 exactly).
- An amount must never be rounded or truncated. A value with more than 2 decimal places must be refused, not changed.
- There must be no upper limit on an amount or a balance; a large value must stay exact.
- Every amount must be written with exactly 2 decimal places, on screen and in the output file.
- The total of all balances after the transfers must equal the total before them, to the cent.
- The sample files must give exactly the closing balances in [DEC-35](../design-analysis/design-decisions.md#dec-35), with a total of 66750.00 before and after.

**How it is checked**
- Unit tests on money values: a value such as `25.60` added and taken away many times stays exact (assistant's pick); `1.234` is refused; a very large value stays exact; every value is written with 2 decimal places.
- The end-to-end test on the sample files checks every closing balance and both totals ([FR-08](02-functional-requirements.md)).
- At run time, the total check stops any run whose total changed ([DEC-24](../design-analysis/design-decisions.md#dec-24)).

<a id="nfr-02"></a>
## NFR-02 Cost of each operation

Decisions: [DEC-18](../design-analysis/design-decisions.md#dec-18), [DEC-31](../design-analysis/design-decisions.md#dec-31).

**Targets**, as growth rates:
- Finding an account by its number must take the same time however many accounts there are.
- Applying one transfer, with all its checks, must take the same time however many accounts and transfers there are. It finds two accounts, checks, then changes two balances, and nothing else.
- Adding one account while loading, including the duplicate check, must take the same time however many accounts are already loaded.
- Listing the final balances, and adding up the total, must grow in proportion to the number of accounts, and visit each account once.
- A rejected transfer must cost no more than an applied one, and must leave nothing to undo, because no balance changes before every check has passed ([DEC-18](../design-analysis/design-decisions.md#dec-18)).

**How it is checked:** design review of the time and space table in [Considerations](09-considerations.md). There is no timing test.

<a id="nfr-03"></a>
## NFR-03 Scale: file size and number of accounts

Decisions: [DEC-32](../design-analysis/design-decisions.md#dec-32), [DEC-03](../design-analysis/design-decisions.md#dec-03).

**Targets**, as growth rates:
- A whole run must take time in proportion to the rows in the balances file plus the rows in the transfers file. No step may compare every row with every other row.
- Memory must grow in proportion to the number of accounts plus the number of transfers. The transfers file must be read one row at a time, so its text is never held in full; one result per transfer is kept, because the report lists every transfer at the end ([DEC-26](../design-analysis/design-decisions.md#dec-26)).
- The balances file is read one row at a time too, and every row of it must be read and checked before any transfer runs, because all its problems must be found first ([DEC-12](../design-analysis/design-decisions.md#dec-12), [DEC-32](../design-analysis/design-decisions.md#dec-32)).
- There must be no fixed limit on the number of accounts or transfers. The only limit is memory: the accounts and one result per transfer must fit in it. That a day's transfers fit in memory is an [assumption](../design-analysis/design-decisions.md#assumptions) ([DEC-32](../design-analysis/design-decisions.md#dec-32)).
- Each run must start from the balances file and keep nothing between runs, so the tenth run of the day costs the same as the first and the same two files always give the same result ([DEC-03](../design-analysis/design-decisions.md#dec-03)).

**How it is checked:** design review, as for NFR-02. There is no timing test and no large test file. What would change for very large files is in [Considerations](09-considerations.md) and out of scope in [Scope](04-scope.md).

<a id="nfr-04"></a>
## NFR-04 Language version and portability

Decisions: [DEC-01](../design-analysis/design-decisions.md#dec-01), [DEC-36](../design-analysis/design-decisions.md#dec-36), [DEC-37](../design-analysis/design-decisions.md#dec-37), [DEC-22](../design-analysis/design-decisions.md#dec-22), [DEC-04](../design-analysis/design-decisions.md#dec-04).

**Targets**
- The program must run on the latest Ruby 3.4.x release, and the same version must be pinned in the project and in the Docker image.
- The program itself must use only Ruby's standard library. The test and quality tools are needed only for development.
- The exact gem versions must be locked and committed, so every machine installs the same ones.
- After `bundle install`, the program must run with one command and no setup beyond that, from any directory, with or without arguments.
- On Windows the program must run as `ruby bin/run`, as the README says.
- Docker must be a working fallback for a reviewer without Ruby 3.4: from a clean checkout it must build, run the sample files, and run the tests.
- Input files with Windows (CRLF) line endings, a missing final newline or a UTF-8 byte-order mark (an invisible marker some editors put at the start of a file) must give the same result as plain files.

**How it is checked**
- CI: a GitHub Actions workflow runs the tests and RuboCop on every push, and must pass.
- Before submission, the Docker image is built from a clean checkout, then the sample files and the tests are run in it ([DEC-36](../design-analysis/design-decisions.md#dec-36), [DEC-37](../design-analysis/design-decisions.md#dec-37)).
- `ruby bin/run` is run by hand on Windows on the sample files before submission, and must give the sample result. (assistant's pick)
- An integration test covers the byte-order mark ([NFR-06](#nfr-06)). Windows line endings and a missing final newline are handled by Ruby's CSV library ([DEC-04](../design-analysis/design-decisions.md#dec-04)) and are checked by design review that the files are read only through that library.

<a id="nfr-05"></a>
## NFR-05 Code organisation and readability

Decisions: [DEC-30](../design-analysis/design-decisions.md#dec-30), [DEC-33](../design-analysis/design-decisions.md#dec-33), [DEC-36](../design-analysis/design-decisions.md#dec-36).

These targets follow the rubric's items on domain models, separation of concerns, and short, readable methods ([Request summary](01-request-summary.md)).

**Targets**
- Each business rule (16 digits, money format, amount above $0, different accounts, no overdraft, no duplicate account, unknown account) must live in exactly one place, inside the domain model it belongs to.
- The code must be split into three layers with one job each: the domain rules, the steps of a run, and the work with files, the screen and the command line. Domain rules must not read files or print anything.
- Names must be plain words from the problem (account, money, transfer), with no design-pattern suffixes or ceremony such as base classes, factories, commands or domain events.
- RuboCop, with its default settings and the RSpec extension, must report zero offences; only its line-ending check, `Layout/EndOfLine`, is turned off, because Git handles line endings ([DEC-36](../design-analysis/design-decisions.md#dec-36)). Its defaults include a limit of 10 lines per method, which sets "short methods" as a number.
- The design reasoning must be explained in the README, not in code comments.
- The high-level design must match the decisions, not the first handwritten sketch ([DEC-33](../design-analysis/design-decisions.md#dec-33)).

**How it is checked**
- RuboCop runs in CI on every push and must report zero offences.
- Design review: each rule above is found in one place only, and each layer does only its own job ([Components](06-components.md)).

<a id="nfr-06"></a>
## NFR-06 Testability and coverage

Decisions: [DEC-34](../design-analysis/design-decisions.md#dec-34), [DEC-36](../design-analysis/design-decisions.md#dec-36), [DEC-24](../design-analysis/design-decisions.md#dec-24), [DEC-30](../design-analysis/design-decisions.md#dec-30), [DEC-28](../design-analysis/design-decisions.md#dec-28).

Three kinds of test are used: unit tests, integration tests and end-to-end tests (defined in the [glossary](10-traceability-glossary-assumptions.md#glossary)).

**Targets**
- The tests must be written with RSpec and must all pass, in random order.
- Each rule must be tested once, at the level where it lives (orthogonal tests: no rule tested twice in two places).
- Fixture files must be used only for file-level behaviour, as listed in [DEC-34](../design-analysis/design-decisions.md#dec-34).
- The end-to-end runs must be these five: the sample files, mixed rejections, all rejected, an invalid balances file, and a wrong number of arguments.
- Test names must read as a description of the behaviour when printed in documentation format.
- Tests must not depend on the clock: a test must be able to fix the run time, so the output file name is known ([DEC-30](../design-analysis/design-decisions.md#dec-30)).
- Tests must not depend on the terminal: a test must be able to read the log lines a run writes ([DEC-28](../design-analysis/design-decisions.md#dec-28)).
- The total-check failure, which correct code never reaches, must still be tested: its error message, no output file, no report and exit status 1 ([DEC-24](../design-analysis/design-decisions.md#dec-24)).
- Test coverage must be measured on every test run and its figure shown in the README. There is no minimum figure that fails the build ([DEC-36](../design-analysis/design-decisions.md#dec-36)).

**How it is checked**
- CI runs the whole suite on every push and must pass.
- SimpleCov produces the coverage report; its figure is copied into the README before submission.
- Design review of the test list against the cases in [DEC-34](../design-analysis/design-decisions.md#dec-34), using the test kind given for each requirement in [Traceability](10-traceability-glossary-assumptions.md).

---

[Back to the solution design](README.md)

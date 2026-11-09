# Feature Specification: Domain and project skeleton

**Feature Branch**: `001-domain`

**Created**: 2026-11-07

**Status**: Draft

**Input**: User description: "Spec 001-domain, short name "domain": the first of the three specs in the Spec Kit brief. Owns FR-03, FR-04, FR-05, FR-06, NFR-01, NFR-02 and NFR-05, and builds the project skeleton and the domain." The full input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#001-domain).

## Sources and ownership

- **Sources, in order of precedence**: [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) (DEC-01 to DEC-38, the source of truth); the solution design pages [02](../../docs/solution-design/02-functional-requirements.md) (FR-03 to FR-06), [03](../../docs/solution-design/03-non-functional-requirements.md), [05](../../docs/solution-design/05-high-level-design.md), [06](../../docs/solution-design/06-components.md) (domain), [07.1](../../docs/solution-design/07-logical-flow/01-apply-one-transfer.md), [07.3](../../docs/solution-design/07-logical-flow/03-successful-transfer.md) to [07.6](../../docs/solution-design/07-logical-flow/06-unknown-account.md), [08.1](../../docs/solution-design/08-alternatives/01-money.md), [08.2](../../docs/solution-design/08-alternatives/02-accounts-and-aggregate-root.md), [09](../../docs/solution-design/09-considerations.md) (time and space, testing strategy) and [10](../../docs/solution-design/10-traceability-glossary-assumptions.md); then `CLAUDE.md` and the [constitution](../../.specify/memory/constitution.md). If this spec ever differs from them, they win.
- **This spec owns**: FR-03 Apply a transfer, FR-04 Below $0 and exactly $0, FR-05 Account not loaded, FR-06 Validation of account numbers and amounts, NFR-01 Money accuracy, NFR-02 Cost of each operation, NFR-05 Code organisation and readability. It owns no other FR or NFR.
- **Built here but owned by `002-file-runner`**: the domain rules behind FR-01, FR-02 and FR-08 (`NegativeBalance`, `DuplicateAccount`, `AccountRepository#include?` and `#all`, `TransferResult`). They are built and unit-tested here, where they live; `002` tests FR-01, FR-02 and FR-08 through `LoadBalances`, `ProcessDailyTransfer` and the runner.
- **How the scenarios are tested**: each acceptance scenario below gives two views. The **domain outcome** is what this spec's tests check by calling the domain directly: the result, the error class and its exact message, and that no balance changes after every failure. The **run outcome** is the page 2 criterion, with standard output, standard error and the exit status stated separately; `002` runs it through the runner with real CSV files and does not own it.

### Conventions used in the run outcomes

These are copied from [page 2](../../docs/solution-design/02-functional-requirements.md#how-to-read-the-acceptance-criteria):

- Every run starts at 2026-11-07 14:30:05 local time, from the project root, with the default log level (warn), and the command is `bin/run balances.csv transfers.csv`. The default output file is then `output/final_balances_2026-11-07_143005.csv`.
- `<timestamp>` stands for the date and time to the microsecond and `<pid>` for the process number. "(nothing)" means the stream stays empty.
- `balances.csv`, with a total of 150.00, is:

```
1111234522226789,100.00
1212343433335665,50.00
0000123412341234,0.00
```

- Where a criterion shows only some lines of the report, the rest follows the report layout in [FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output). Lines marked **(derived)** are not printed on page 2 for that criterion; they are built from the FR-08 layout, the masking rule in AC-09.6 and the all-rejected warning in [DEC-21](../../docs/design-analysis/design-decisions.md#dec-21), and they add no behaviour. Each single-row example uses the row as line 1 of `transfers.csv`.
- When every transfer in a run is rejected, standard output also holds `Warning: All transfers were rejected; check this is the right file.` after the summary, and standard error ends with `W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.` ([DEC-21](../../docs/design-analysis/design-decisions.md#dec-21)).

## Clarifications

### Session 2026-11-07

- Q: When a transfers row has the wrong number of fields, does its `TransferResult` keep every field the row had, as written? → A: Yes. It keeps all of the row's fields, in order, as written after trimming, so the number of fields gives `N fields, expected 3` for the report and the log takes from, to and amount by position (page 2 FR-02 and FR-08; page 10 pick 12).
- Q: Are two `Money` values equal when one was written with a minus sign and the other was not, such as `-0` and `0`? → A: Yes. Equality and comparison use the exact amount only; the recorded minus sign changes only whether the value counts as negative. A `Money` made by adding or taking away counts as negative only when its amount is below 0.
- Q: Should `Account#withdraw` and `Account#deposit` themselves refuse an amount of $0 or less? → A: No. The amount-above-$0 rule lives only in `Transfer` (DEC-30, FR-028); `TransferService` passes them only the amount of a valid `Transfer`, so no test calls them with $0 or less.

### Session 2026-11-09 (code review)

- Q: Should `Account#withdraw` and `Account#deposit` guard against an amount of $0 or less? → A: Yes, as the developer asked in the code review (P33): each raises `ArgumentError` for such an amount, a programming error. The business rule, with `InvalidAmount` and its message, still lives only in `Transfer` (FR-008, FR-028), so no transfer outcome changes ([DEC-18](../../docs/design-analysis/design-decisions.md#dec-18), [DEC-30](../../docs/design-analysis/design-decisions.md#dec-30)). This answer replaces the one above.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A valid transfer moves the money, all or nothing (Priority: P1)

The company asks for an amount to move from one of its accounts to another. When every check passes, the amount leaves the paying account and arrives in the receiving account. When any check fails, neither balance changes, and the reason is exactly one of six reason codes, the first check the transfer fails ([FR-03](../../docs/solution-design/02-functional-requirements.md#fr-03-apply-a-transfer); [DEC-13](../../docs/design-analysis/design-decisions.md#dec-13), [DEC-14](../../docs/design-analysis/design-decisions.md#dec-14), [DEC-16](../../docs/design-analysis/design-decisions.md#dec-16), [DEC-18](../../docs/design-analysis/design-decisions.md#dec-18), [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19)).

**Why this priority**: moving money correctly is the core of the challenge; everything else exists to support it.

**Independent Test**: build three accounts holding 100.00, 50.00 and 0.00 in a repository, apply transfers through `TransferService`, and check the balances and the errors raised. No file, clock or terminal is needed.

**Acceptance Scenarios**:

1. **AC-03.1 A valid transfer moves the money** (FR-03; DEC-13, DEC-18).
   - **Given** the accounts `1111234522226789` 100.00, `1212343433335665` 50.00 and `0000123412341234` 0.00, **When** a `Transfer` from `1111234522226789` to `1212343433335665` of `30.00` is applied, **Then** the balances are 70.00, 80.00 and 0.00 and no error is raised (domain outcome).
   - Run outcome, with `transfers.csv` holding `1111234522226789,1212343433335665,30.00`:
     - Standard output contains:

       ```
         Line 1  applied  1111234522226789 -> 1212343433335665  30.00
       ...
       Final balances
         Account           Opening  Closing
         1111234522226789   100.00    70.00
         1212343433335665    50.00    80.00
         0000123412341234     0.00     0.00
       ```

     - Standard error: (nothing)
     - Exit status: 0
2. **AC-03.2 A rejected transfer changes nothing and the run continues** (FR-03; DEC-14, DEC-18).
   - **Given** the three accounts above, **When** a transfer is refused for any of the domain reasons (`InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `UnknownAccount`, `InsufficientFunds`), **Then** both accounts keep their balances, the total stays 150.00, and the next transfer can be applied (domain outcome). `TransferService` finds both accounts before it withdraws, and deposits only after the withdrawal succeeded, so nothing is ever undone.
   - Run outcome, for any transfer rejected for any of the six reasons in AC-03.3:
     - Standard output: the report in the FR-08 layout, listing the row as `rejected` with its reason code, and the final balances unchanged.
     - Standard error: the row's warn line, `W, [<timestamp> #<pid>]  WARN -- : Line N rejected: ...` with its reason code (FR-09, owned by `002`).
     - Exit status: 0
3. **AC-03.3 Each rejected transfer has exactly one reason: the first check it fails, in this order** (FR-03; DEC-19).

   | Order | Reason code | When | Refused by (domain outcome) |
   |---|---|---|---|
   | 1 | `malformed_row` | the row does not have exactly 3 fields | the transfers reader marks the row (`002`); no domain error |
   | 2 | `invalid_account_number` | the from or to account number is not exactly 16 digits | `AccountNumber` raises `InvalidAccountNumber` |
   | 3 | `invalid_amount` | the amount is empty, not a number, has more than 2 decimals, or is $0 or less | `Money` (format) or `Transfer` (above $0) raises `InvalidAmount` |
   | 4 | `same_account` | the from and to accounts are the same | `Transfer` raises `SameAccount` |
   | 5 | `unknown_account` | the from or to account is not in the balances file | `AccountRepository#find` raises `UnknownAccount` |
   | 6 | `insufficient_funds` | the from account's balance would go below $0 | `Account#withdraw` raises `InsufficientFunds` |

   - **Given** `1111234522226789`, `1111234522226789` and `0`, **When** the `Transfer` is built, **Then** it raises `InvalidAmount` with the message `amount "0" must be greater than 0.00`, not `SameAccount`, because the amount is checked first (domain outcome; DEC-19, page 6 `Transfer`).
   - **Given** `9999888877776666`, `9999888877776666` and `5.00`, and a repository that does not hold `9999888877776666`, **When** the `Transfer` is built, **Then** it raises `SameAccount` with the message `account 9999888877776666 cannot transfer to itself` before any lookup, so the reason is not `unknown_account` (domain outcome).
   - **Given** a `Transfer` from `1111234522226789` (balance 100.00) to `9999888877776666`, which is not loaded, of `1000000.00`, **When** it is applied, **Then** `UnknownAccount` is raised, not `InsufficientFunds`, because both lookups run before the withdrawal, and the balances are unchanged (domain outcome; DEC-18).
   - The first example on page 2, `12345,1212343433335665,abc`, depends on the order in which `ProcessDailyTransfer` builds the values (both `AccountNumber`s before the `Money`, page 7.1); that order is owned by `002`. The domain part is that `AccountNumber` raises `InvalidAccountNumber` for `12345` whatever the amount is.
   - Run outcomes (each row alone in `transfers.csv`; every transfer is rejected, so the all-rejected warning follows):

     | Row | Standard output contains | Standard error | Exit status |
     |---|---|---|---|
     | `12345,1212343433335665,abc` | `  Line 1  rejected  12345 -> 1212343433335665  abc  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: *2345 -> ************5665 abc invalid_account_number` **(derived)**, then the all-rejected warn line | 0 |
     | `1111234522226789,1111234522226789,0` | `  Line 1  rejected  1111234522226789 -> 1111234522226789  0  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************6789 0 invalid_amount` **(derived)**, then the all-rejected warn line | 0 |
     | `9999888877776666,9999888877776666,5.00` | `  Line 1  rejected  9999888877776666 -> 9999888877776666  5.00  same_account` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6666 -> ************6666 5.00 same_account` **(derived)**, then the all-rejected warn line | 0 |

4. **Two equal transfers are both applied** (FR-03; DEC-16).
   - **Given** the three accounts above, **When** two `Transfer`s from `1111234522226789` to `0000123412341234` of `20.00` are applied one after the other, **Then** both are applied and the balances are 60.00, 50.00 and 40.00 (domain outcome). There is no duplicate check.
   - Run outcome: covered by AC-07.1 on page 2 (FR-07, owned by `002`); line 1 (`0000123412341234,1212343433335665,20.00`) is rejected as `insufficient_funds`.
     - Standard output contains `Final balances`, `  Account           Opening  Closing`, `  1111234522226789   100.00    60.00`, `  1212343433335665    50.00    50.00`, `  0000123412341234     0.00    40.00`.
     - Standard error: `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************5665 20.00 insufficient_funds` **(derived)**.
     - Exit status: 0

5. **The outcome of a transfers row is one `TransferResult`** (FR-03 domain part; FR-08 owned by `002`; DEC-19, DEC-06).
   - **Given** a line number, the row's values as written (after trimming) and the outcome, **When** a `TransferResult` is built, **Then** it says whether it was applied, gives no reason code when applied and exactly one of the six reason codes when rejected, and returns its line number and values unchanged. A rejected header-looking row also carries the header hint `This looks like a header row; files must not have a header.` (domain outcome).
   - **Given** line 4 with the two fields `1111234522226789` and `1212343433335665`, **When** a rejected `TransferResult` with `malformed_row` is built, **Then** it returns both fields in that order, so their number is 2; a row of 4 fields returns all 4 (domain outcome; DEC-19, page 2 AC-02.1).
   - Run outcome: none of its own; `ReportPrinter` and the log lines that read it are owned by `002`.

---

### User Story 2 - No balance ever goes below $0, and exactly $0 is allowed (Priority: P1)

The company may empty an account to exactly $0.00, but no transfer may take an account below $0.00. An account already at $0.00 cannot pay anything ([FR-04](../../docs/solution-design/02-functional-requirements.md#fr-04-a-transfer-that-would-take-an-account-below-0-and-exactly-0); [DEC-10](../../docs/design-analysis/design-decisions.md#dec-10), [DEC-13](../../docs/design-analysis/design-decisions.md#dec-13), [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19)).

**Why this priority**: "never below $0" is the challenge's one stated business rule.

**Independent Test**: build an `Account` and call `withdraw` with amounts just below, at and above its balance; then apply the same amounts through `TransferService` and check both balances.

**Acceptance Scenarios**:

1. **AC-04.1 Below $0 by one cent is rejected, with both balances unchanged** (FR-04; DEC-13, DEC-18).
   - **Given** the three accounts of `balances.csv`, **When** a `Transfer` from `1111234522226789` to `1212343433335665` of `100.01` is applied, **Then** `Account#withdraw` raises `InsufficientFunds` with the message `account 1111234522226789 cannot pay 100.01 from a balance of 100.00`, `deposit` is never called, and the balances stay 100.00, 50.00 and 0.00 (domain outcome).
   - Run outcome, with `transfers.csv` holding `1111234522226789,1212343433335665,100.01`:
     - Standard output contains `  Line 1  rejected  1111234522226789 -> 1212343433335665  100.01  insufficient_funds`, and the final balances 100.00, 50.00 and 0.00.
     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds
       W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
       ```

     - Exit status: 0
2. **AC-04.2 Exactly $0 is applied** (FR-04; DEC-13).
   - **Given** the three accounts, **When** a `Transfer` from `1111234522226789` to `1212343433335665` of `100.00` is applied, **Then** no error is raised and the balances are 0.00, 150.00 and 0.00 (domain outcome).
   - Run outcome, with `transfers.csv` holding `1111234522226789,1212343433335665,100.00`:
     - Standard output contains `  Line 1  applied  1111234522226789 -> 1212343433335665  100.00` **(derived)** and the final balances, with the opening balances 100.00, 50.00 and 0.00 and the closing balances 0.00, 150.00 and 0.00:

       ```
       Account           Opening  Closing
       1111234522226789   100.00     0.00
       1212343433335665    50.00   150.00
       0000123412341234     0.00     0.00
       ```

       (each line is indented two spaces in the output)
     - Standard error: (nothing)
     - Exit status: 0 (a completed run, [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25))
3. **AC-04.3 An account already at $0.00 cannot pay anything** (FR-04; DEC-10, DEC-13).
   - **Given** the three accounts, **When** a `Transfer` from `0000123412341234` to `1111234522226789` of `0.01` is applied, **Then** `InsufficientFunds` is raised with the message `account 0000123412341234 cannot pay 0.01 from a balance of 0.00` and the balances are unchanged (domain outcome).
   - Run outcome, with `transfers.csv` holding `0000123412341234,1111234522226789,0.01`:
     - Standard output contains `  Line 1  rejected  0000123412341234 -> 1111234522226789  0.01  insufficient_funds` **(derived)** and the final balances unchanged.
     - Standard error: `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************6789 0.01 insufficient_funds` **(derived)**, then the all-rejected warn line.
     - Exit status: 0

---

### User Story 3 - A transfer naming an account that is not loaded is refused (Priority: P2)

Only accounts from the balances file exist. A transfer to or from any other valid 16-digit account number is refused, and no account is ever created ([FR-05](../../docs/solution-design/02-functional-requirements.md#fr-05-a-transfer-naming-an-account-that-is-not-loaded); [DEC-17](../../docs/design-analysis/design-decisions.md#dec-17), [DEC-31](../../docs/design-analysis/design-decisions.md#dec-31)).

**Why this priority**: it keeps the total of all balances fixed and stops money moving to accounts the company never listed; it is less common than the $0 rule.

**Independent Test**: call `AccountRepository#find` with a number it does not hold, then apply transfers naming such a number through `TransferService`, and check the error, the balances and `AccountRepository#all`.

**Acceptance Scenarios**:

1. **AC-05.1 Unknown to account** (FR-05; DEC-17, DEC-18).
   - **Given** the three accounts, **When** a `Transfer` from `1111234522226789` to `9999888877776666` of `10.00` is applied, **Then** `UnknownAccount` is raised with the message `account 9999888877776666 is not loaded`, `withdraw` and `deposit` are never called, the balances stay 100.00, 50.00 and 0.00, and `all` still returns only the three loaded accounts (domain outcome).
   - Run outcome, with `transfers.csv` holding `1111234522226789,9999888877776666,10.00`:
     - Standard output contains `  Line 1  rejected  1111234522226789 -> 9999888877776666  10.00  unknown_account`, and the final balances list only the three loaded accounts, unchanged.
     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************6666 10.00 unknown_account
       W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
       ```

     - Exit status: 0
2. **AC-05.2 Unknown from account** (FR-05; DEC-17).
   - **Given** the three accounts, **When** a `Transfer` from `9999888877776666` to `1111234522226789` of `10.00` is applied, **Then** `UnknownAccount` is raised with the message `account 9999888877776666 is not loaded` and no balance changes (domain outcome).
   - Run outcome, with `transfers.csv` holding `9999888877776666,1111234522226789,10.00`:
     - Standard output contains `  Line 1  rejected  9999888877776666 -> 1111234522226789  10.00  unknown_account` **(derived)** and the final balances unchanged.
     - Standard error: `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6666 -> ************6789 10.00 unknown_account` **(derived)**, then the all-rejected warn line.
     - Exit status: 0
3. **Both accounts unknown** (FR-05; DEC-17, page 7.6).
   - **Given** a repository that holds neither account, **When** a `Transfer` from `9999888877776666` to `8888777766665555` of `10.00` is applied, **Then** `UnknownAccount` is raised naming the from account, `account 9999888877776666 is not loaded`, because the from account is looked up first (domain outcome). The reason code is `unknown_account` whichever side is unknown.
   - Run outcome: none of its own (not a page 2 criterion; the reason code `unknown_account` is the same as AC-05.1 and AC-05.2).
4. **`find` never creates an account** (FR-05; DEC-17, DEC-31).
   - **Given** an empty repository, **When** `find` is called with `9999888877776666`, **Then** it raises `UnknownAccount`, and afterwards `include?` for that number is false and `all` is empty (domain outcome).
   - Run outcome: none of its own (covered by AC-05.1).

---

### User Story 4 - Only valid account numbers and exact money values are accepted (Priority: P1)

An account number is exactly 16 digits, kept as text so leading zeros stay. A money value is digits, optionally followed by a point and 1 or 2 digits, with an optional leading minus sign that makes it negative; it is never rounded or truncated. A transfer amount must be above $0. A starting balance may be $0.00 but must not be negative ([FR-06](../../docs/solution-design/02-functional-requirements.md#fr-06-validation-of-account-numbers-and-amounts); [DEC-08](../../docs/design-analysis/design-decisions.md#dec-08), [DEC-09](../../docs/design-analysis/design-decisions.md#dec-09), [DEC-10](../../docs/design-analysis/design-decisions.md#dec-10), [DEC-11](../../docs/design-analysis/design-decisions.md#dec-11), [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19)).

**Why this priority**: every transfer and every balance passes through these two values; a wrong rule here gives a wrong result everywhere.

**Independent Test**: build `AccountNumber`, `Money`, `Transfer` and the `Account` opening-balance check from each value in the tables below, and check the value or the error class and its exact message.

**Acceptance Scenarios**:

1. **AC-06.1 Account numbers** (FR-06; DEC-08).
   - Domain outcome: **Given** the text below, **When** an `AccountNumber` is built, **Then**:

     | Text | Domain outcome |
     |---|---|
     | `1111234522226789` | valid; its text is `1111234522226789` |
     | `0000123412341234` | valid; its text keeps the leading zeros, `0000123412341234`, and it equals another `AccountNumber` built from the same text |
     | `111123452222678` (15 digits) | `InvalidAccountNumber`: `account number "111123452222678" must be exactly 16 digits` |
     | `11112345222267890` (17 digits) | `InvalidAccountNumber`: `account number "11112345222267890" must be exactly 16 digits` |
     | `1111O34522226789` (letter O) | `InvalidAccountNumber`: `account number "1111O34522226789" must be exactly 16 digits` |
     | `1111-2345-2222-6789` | `InvalidAccountNumber`: `account number "1111-2345-2222-6789" must be exactly 16 digits` |
     | `12345` | `InvalidAccountNumber`: `account number "12345" must be exactly 16 digits` (the text after `Line 3: ` in AC-01.4) |
     | (empty) | `InvalidAccountNumber`: `account number "" must be exactly 16 digits` (the text after `Line 2: ` in AC-01.6) |

     There is no check-digit check: all five sample account numbers (`1111234522226789`, `1111234522221234`, `2222123433331212`, `1212343433335665`, `3212343433335755`) are valid.
   - Run outcome (page 2): **Given** `balances.csv` and a transfer from the value below to `1212343433335665` for `10.00`, **When** the program runs, **Then** the exit status is 0 for every row, and:

     | From value | Result | Standard output contains | Standard error |
     |---|---|---|---|
     | `1111234522226789` | applied | `  Line 1  applied  1111234522226789 -> 1212343433335665  10.00` **(derived)** | (nothing) |
     | `0000123412341234` | rejected `insufficient_funds` (the leading zeros match the balances file) | `  Line 1  rejected  0000123412341234 -> 1212343433335665  10.00  insufficient_funds` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************5665 10.00 insufficient_funds` **(derived)**, then the all-rejected warn line |
     | `111123452222678` (15 digits) | rejected `invalid_account_number` | `  Line 1  rejected  111123452222678 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ***********2678 -> ************5665 10.00 invalid_account_number` **(derived)**, then the all-rejected warn line |
     | `11112345222267890` (17 digits) | rejected `invalid_account_number` | `  Line 1  rejected  11112345222267890 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: *************7890 -> ************5665 10.00 invalid_account_number` **(derived)**, then the all-rejected warn line |
     | `1111O34522226789` (letter O) | rejected `invalid_account_number` | `  Line 1  rejected  1111O34522226789 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 10.00 invalid_account_number` **(derived)**, then the all-rejected warn line |
     | `1111-2345-2222-6789` | rejected `invalid_account_number` | `  Line 1  rejected  1111-2345-2222-6789 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ***************6789 -> ************5665 10.00 invalid_account_number` **(derived)**, then the all-rejected warn line |

     Every rejected row also puts the all-rejected warning in standard output.

2. **AC-06.2 Amounts** (FR-06; DEC-09, DEC-10).
   - Domain outcome for `Money`: **Given** the text below, **When** a `Money` is built for a transfer amount, **Then**:

     | Text | Domain outcome |
     |---|---|
     | `10`, `10.5`, `10.50`, `007.50` | valid; written as `10.00`, `10.50`, `10.50`, `7.50` |
     | `0`, `0.00` | valid money, written as `0.00`; not negative |
     | `-5.00`, `-0`, `-0.00` | valid money, and negative (the minus sign is recorded, so `-0` and `-0.00` count as negative); `-0` and `-0.00` still equal `Money` built from `0` |
     | `1.234` | `InvalidAmount`: `amount "1.234" has more than 2 decimal places` (never rounded) |
     | (empty) | `InvalidAmount`: `amount is empty` |
     | `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0`, `1,000.00` | `InvalidAmount`: `amount "<text>" is not a valid amount`, for example `amount "abc" is not a valid amount` |

   - Domain outcome for `Transfer`: **Given** a valid from and to account and the amount below, **When** the `Transfer` is built, **Then** `0`, `0.00`, `-5.00`, `-0` and `-0.00` raise `InvalidAmount` with the message `amount "<text>" must be greater than 0.00`, for example `amount "0" must be greater than 0.00` and `amount "-0.00" must be greater than 0.00`; `0.01` and above are accepted.
   - Run outcome (page 2): **Given** `balances.csv` and a transfer from `1111234522226789` to `1212343433335665` with the amount below, **When** the program runs, **Then** the exit status is 0 for every row, and:

     | Amount as written | Result | Standard output contains | Standard error |
     |---|---|---|---|
     | `10`, `10.5`, `10.50`, `007.50` | applied, shown as `10.00`, `10.50`, `10.50`, `7.50` | `  Line 1  applied  1111234522226789 -> 1212343433335665  10.00` (and `10.50`, `10.50`, `7.50`) **(derived)** | (nothing) |
     | `0`, `0.00` | rejected `invalid_amount` (must be above $0) | `  Line 1  rejected  1111234522226789 -> 1212343433335665  <as written>  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 <as written> invalid_amount` **(derived)**, then the all-rejected warn line |
     | `-5.00`, `-0`, `-0.00` | rejected `invalid_amount` (negative) | as above | as above |
     | `1.234` | rejected `invalid_amount` (never rounded) | as above | as above |
     | empty, `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0` | rejected `invalid_amount` | as above; an empty amount is shown as `""` | as above; an empty amount is shown as `""` |
     | `"1,000.00"` (quoted) | rejected `invalid_amount` | as above, with the value `1,000.00` | as above, with the value `1,000.00` |
     | `1,000.00` (not quoted) | rejected `malformed_row`, because the comma makes 4 fields | `  Line 1  rejected  malformed_row: 4 fields, expected 3` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 1 malformed_row` **(derived)**, then the all-rejected warn line |

     A rejected line shows the values as written in the file, after trimming spaces: `10.` is shown as `10.`, not `10.00`. Every rejected row also puts the all-rejected warning in standard output. The `malformed_row` row is decided by the transfers reader (`002`), not by the domain.

3. **AC-06.3 The same rules hold in the balances file** (FR-06; FR-01 owned by `002`; DEC-09, DEC-10, DEC-11).
   - Domain outcome: **Given** the text below, **When** a `Money` is built for an opening balance and the `Account` opening-balance check runs, **Then**:

     | Text | Domain outcome |
     |---|---|
     | `0`, `0.00` | valid opening balance, written as `0.00` |
     | `5000.00`, `550` | valid, written as `5000.00`, `550.00` |
     | `-5.00` | `NegativeBalance`: `balance "-5.00" must not be negative` (the text after `Line 6: ` in AC-01.4) |
     | `-0`, `-0.00` | `NegativeBalance`: `balance "-0" must not be negative`, `balance "-0.00" must not be negative` |
     | `1.234` | `InvalidAmount`: `balance "1.234" has more than 2 decimal places` (the text after `Line 7: ` in AC-01.4) |
     | `abc` | `InvalidAmount`: `balance "abc" is not a valid amount` (the text after `Line 1: ` in AC-01.5) |
     | (empty) | `InvalidAmount`: `balance is empty` (the text after `Line 2: ` in AC-01.6) |

     The opening-balance check needs only the `Money`, so it can run even when the row's account number is invalid (page 6 `Account`).
   - Run outcome: the balances-file errors are FR-01 criteria (AC-01.4 to AC-01.6), owned and run by `002`. For example, AC-01.4 gives standard output (nothing), exit status 1, and on standard error the lines `  Line 6: balance "-5.00" must not be negative` and `  Line 7: balance "1.234" has more than 2 decimal places` inside the `Error: the balances file is invalid (5 problems):` message.

---

### User Story 5 - The repository keeps the accounts, one per number, in load order (Priority: P2)

The run's accounts are held in one place. It refuses a second account with the same number, says whether a number is already held, finds an account by its number, and lists the accounts in the order they were added. Each add, check and find takes the same time however many accounts there are (supports [FR-01](../../docs/solution-design/02-functional-requirements.md#fr-01-load-the-balances-file), which `002` owns; [NFR-02](../../docs/solution-design/03-non-functional-requirements.md#nfr-02); [DEC-11](../../docs/design-analysis/design-decisions.md#dec-11), [DEC-12](../../docs/design-analysis/design-decisions.md#dec-12), [DEC-31](../../docs/design-analysis/design-decisions.md#dec-31)).

**Why this priority**: `LoadBalances` (`002`) relies on these rules to report duplicates and keep load order; the report and the output file rely on `all`.

**Independent Test**: add accounts to an empty `AccountRepository` and call `include?`, `find`, `add` and `all`.

**Acceptance Scenarios**:

1. **Given** accounts `1111234522226789`, `1212343433335665` and `0000123412341234` added in that order, **When** `all` is called, **Then** it returns them in that order (domain outcome; DEC-31).
- Run outcome: covered by AC-01.1 on page 2 (FR-01, owned and run by `002`): standard output lists the final balances of the accounts in file order, standard error (nothing), exit status 0.
2. **Given** `1111234522226789` is held, **When** `include?` is called with an `AccountNumber` built from `1111234522226789`, **Then** it is true; for `9999888877776666` it is false (domain outcome; DEC-12, DEC-31).
- Run outcome: none of its own (covered by AC-01.4, owned by `002`).
3. **Given** `1111234522226789` is held, **When** another `Account` with that number is added, whether its balance is the same or different, **Then** `add` raises `DuplicateAccount` with the message `account 1111234522226789 appears more than once`, and the first account and its balance are kept (domain outcome; DEC-11, DEC-31).
4. **Given** `1111234522226789` is held, **When** `find` is called with it, **Then** it returns that same `Account`, so a change made through it is seen by `all` (domain outcome).
- Run outcome: none of its own (covered by AC-01.1, owned by `002`).
5. Run outcome: the duplicate account appears on standard error as `  Line 5: account 1111234522226789 appears more than once (first on line 1)` in AC-01.4, with standard output (nothing) and exit status 1. That criterion is FR-01, owned and run by `002`; `LoadBalances` adds `Line N: ` and ` (first on line M)` around the domain wording.

---

### User Story 6 - Money stays exact to the cent (Priority: P2)

Every amount and balance is exact after any number of transfers, with no fraction of a cent gained or lost, and is always written with exactly 2 decimal places ([NFR-01](../../docs/solution-design/03-non-functional-requirements.md#nfr-01); [DEC-09](../../docs/design-analysis/design-decisions.md#dec-09), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).

**Why this priority**: a balance one cent off fails "calculates test files accurately"; the other stories depend on exact arithmetic.

**Independent Test**: add and take away `Money` values many times and compare with the exact expected value.

**Acceptance Scenarios**:

1. **Given** `Money` of `0.00`, **When** `25.60` is added 1,000 times and then taken away 1,000 times, **Then** the value after the additions is exactly `25600.00` and the final value is exactly `0.00` (domain outcome; NFR-01, solution design pick 21).
- Run outcome: none of its own (covered by AC-08.1, owned by `002`).
2. **Given** `Money` of `0.10` and `0.20`, **When** they are added, **Then** the sum is exactly `0.30` (domain outcome).
- Run outcome: none of its own (covered by AC-08.1, owned by `002`).
3. **Given** a very large value such as `123456789012345678901234567890.12`, **When** `0.01` is added, **Then** the result is written as `123456789012345678901234567890.13`; there is no upper limit (domain outcome; DEC-09).
- Run outcome: none of its own (covered by AC-08.1, owned by `002`).
4. **Given** the five sample accounts `1111234522226789` 5000.00, `1111234522221234` 10000.00, `2222123433331212` 550.00, `1212343433335665` 1200.00 and `3212343433335755` 50000.00, **When** the four sample transfers are applied through `TransferService` in this order: `1111234522226789` to `1212343433335665` `500.00`; `3212343433335755` to `2222123433331212` `1000.00`; `3212343433335755` to `1111234522226789` `320.50`; `1111234522221234` to `1212343433335665` `25.60`, **Then** the balances are exactly 4820.50, 9974.40, 1550.00, 1725.60 and 48679.50, and their total is 66750.00 before and after (domain outcome; DEC-35).
5. Run outcome: the sample files end to end are AC-08.1 (FR-08, owned and run by `002`): standard error (nothing), exit status 0, and the final balances section of standard output:

   ```
   Final balances
     Account            Opening   Closing
     1111234522226789   5000.00   4820.50
     1111234522221234  10000.00   9974.40
     2222123433331212    550.00   1550.00
     1212343433335665   1200.00   1725.60
     3212343433335755  50000.00  48679.50
   ```

---

### User Story 7 - A developer can install, test and style-check the project (Priority: P3)

A developer (or reviewer) clones the project, installs its gems, runs the tests and the style checker, and gets a readable test list in random order, a coverage report and zero style offences. The code is organised so each rule lives in one place inside the model it belongs to ([NFR-05](../../docs/solution-design/03-non-functional-requirements.md#nfr-05); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-30](../../docs/design-analysis/design-decisions.md#dec-30), [DEC-33](../../docs/design-analysis/design-decisions.md#dec-33), [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).

**Why this priority**: it is the frame the other stories are built and checked in, but it delivers no business rule by itself.

**Independent Test**: from a clean checkout with Ruby 3.4, run `bundle install`, `bundle exec rspec` and `bundle exec rubocop`.

**Acceptance Scenarios**:

1. **Given** a clean checkout and Ruby at the version in `.ruby-version`, **When** `bundle install` runs, **Then** it installs exactly the versions in the committed `Gemfile.lock`: runtime `csv`, `bigdecimal` and `logger`, and development `rspec`, `simplecov`, `rubocop` and `rubocop-rspec`, and no other gem is named in the `Gemfile` (DEC-01, DEC-36).
2. **Given** the installed gems, **When** `bundle exec rspec` runs, **Then** every spec passes, in random order with the seed printed, each test name printed as a sentence (documentation format), and a coverage report is produced in `coverage/`, with no minimum figure that fails the run (DEC-34, DEC-36).
3. **Given** the installed gems, **When** `bundle exec rubocop` runs with its default settings and `rubocop-rspec`, **Then** it reports zero offences (NFR-05; DEC-36).
4. **Given** the project, **When** `git status` runs after the tests, **Then** `coverage/` and `output/` are ignored (DEC-27, DEC-36).
5. Run outcome: none; this story has no standard output, standard error or exit status of `bin/run`.

---

### Edge Cases

Each is covered by a domain unit test in this spec (DEC-34):

- A transfer that leaves exactly $0.00 is applied; one cent more is refused (DEC-13; AC-04.1, AC-04.2).
- A rejected transfer leaves both balances unchanged, for each of `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `UnknownAccount` and `InsufficientFunds` (DEC-18; AC-03.2).
- A transfer from a known account without enough money to an unknown account gets `UnknownAccount`, because both lookups come before the withdrawal (DEC-18, DEC-19).
- A transfer from an account to itself with an amount of 0 gets `InvalidAmount`, because the amount is checked before the accounts (DEC-19).
- A transfer from an account to itself that is also not loaded gets `SameAccount`, because `Transfer` refuses it before any lookup (DEC-19).
- Both accounts unknown: `UnknownAccount` names the from account (DEC-17).
- `-0` and `-0.00` are negative: refused as a transfer amount (`InvalidAmount`) and as an opening balance (`NegativeBalance`) (DEC-09). As `Money` they still equal `0`, because equality uses the amount only.
- A `Money` made by taking away is negative only when its amount is below 0 (for example `5.00` minus `5.00` is `0.00` and not negative).
- A `malformed_row` result keeps every field of the row, whether it has fewer or more than 3 (DEC-19).
- `0` and `0.00` are a valid opening balance but not a valid transfer amount (DEC-10).
- `007.50` is valid and written as `7.50`; `10.` and `.50` are invalid (DEC-09).
- `+100`, `1e3`, `$100`, `1,000.00` and values with spaces inside are invalid (DEC-09).
- A value with more than 2 decimal places is refused, never rounded or truncated, including a negative one such as `-1.234` (DEC-09).
- An account number with leading zeros keeps them and equals another built from the same text (DEC-08).
- An account number of 15 or 17 digits, with a letter, with dashes, or empty is invalid (DEC-08).
- A duplicate account is refused on `add` whether its balance is the same or different, and the first one is kept (DEC-11, DEC-31).
- `find` for a number not held raises and never adds an account (DEC-17, DEC-31).
- Two equal transfers are both applied (DEC-16).
- A very large amount stays exact (DEC-09).

## Requirements *(mandatory)*

### Functional Requirements

**Account numbers ([FR-06](../../docs/solution-design/02-functional-requirements.md#fr-06-validation-of-account-numbers-and-amounts))**

- **FR-001** (FR-06; DEC-08): `AccountNumber` MUST accept only text of exactly 16 characters, each a digit 0 to 9, and MUST raise `InvalidAccountNumber` for any other text, with the message `account number "<text>" must be exactly 16 digits`, where `<text>` is the text it was given.
- **FR-002** (FR-06; DEC-08): `AccountNumber` MUST keep the number as text, never as an integer, so leading zeros stay; it MUST give its full text, and two `AccountNumber`s with the same text MUST be equal and usable as the same lookup key. It MUST NOT run a check-digit (Luhn) check and MUST NOT mask itself.

**Money ([FR-06](../../docs/solution-design/02-functional-requirements.md#fr-06-validation-of-account-numbers-and-amounts), [NFR-01](../../docs/solution-design/03-non-functional-requirements.md#nfr-01))**

- **FR-003** (FR-06, NFR-01; DEC-09): `Money` MUST accept text that is digits, optionally followed by a point and 1 or 2 digits, with an optional leading minus sign, and MUST hold the value as an exact decimal, never as floating point. A value never passes through floating point on the way in.
- **FR-004** (FR-06; DEC-09): `Money` MUST record that a minus sign was written, so `-0` and `-0.00` count as negative, and MUST NOT itself decide whether a negative value is allowed. The recorded sign changes only whether the value counts as negative; a `Money` made by adding or taking away counts as negative only when its amount is below 0.
- **FR-005** (FR-06, NFR-01; DEC-09): `Money` MUST raise `InvalidAmount` for: empty text (message `<label> is empty`); digits with a point and 3 or more decimal places, with or without a leading minus sign (message `<label> "<text>" has more than 2 decimal places`); and any other text (message `<label> "<text>" is not a valid amount`). `<label>` is `balance` for an opening balance and `amount` for a transfer amount; `<text>` is the text as given. It MUST never round or truncate.
- **FR-006** (NFR-01; DEC-09): `Money` MUST support adding, taking away and comparing values exactly, with no upper limit, and two `Money` values of the same amount MUST be equal, whatever sign was written (`-0` equals `0`).
- **FR-007** (NFR-01; DEC-09): `Money` MUST write itself with exactly 2 decimal places and no leading zeros before the units digit: `550` is written `550.00`, `007.50` is written `7.50`, `10.5` is written `10.50`.

**Transfers ([FR-03](../../docs/solution-design/02-functional-requirements.md#fr-03-apply-a-transfer), [FR-06](../../docs/solution-design/02-functional-requirements.md#fr-06-validation-of-account-numbers-and-amounts))**

- **FR-008** (FR-03, FR-06; DEC-10, DEC-13, DEC-19, DEC-30): `Transfer` MUST hold a from `AccountNumber`, a to `AccountNumber` and a `Money` amount. It MUST first raise `InvalidAmount` when the amount is $0 or less, including a negative zero, with the message `amount "<text>" must be greater than 0.00`, and only then raise `SameAccount` when from and to are equal, with the message `account <number> cannot transfer to itself`.
- **FR-009** (FR-03; DEC-30): `Transfer` MUST NOT look up accounts, check balances, hold `Account`s or change anything.

**Accounts ([FR-04](../../docs/solution-design/02-functional-requirements.md#fr-04-a-transfer-that-would-take-an-account-below-0-and-exactly-0), [FR-06](../../docs/solution-design/02-functional-requirements.md#fr-06-validation-of-account-numbers-and-amounts))**

- **FR-010** (FR-04; DEC-13, DEC-30): `Account` MUST be the aggregate root: it owns its `AccountNumber` and its balance, and its balance MUST change only through `withdraw` and `deposit`.
- **FR-011** (FR-04; DEC-13, DEC-18): `Account#withdraw(money)` MUST compare first and change the balance only when the balance minus the amount is $0.00 or more; otherwise it MUST raise `InsufficientFunds` with the message `account <number> cannot pay <amount> from a balance of <balance>` (amounts written with 2 decimal places) and leave the balance unchanged. A withdrawal that leaves exactly $0.00 MUST succeed.
- **FR-012** (FR-03; DEC-18, DEC-30): `Account#deposit(money)` MUST add the amount and cannot fail for a valid transfer. `withdraw` and `deposit` MUST each raise `ArgumentError` with the message `amount <amount> must be greater than 0.00` for an amount of $0 or less, before changing anything: a guard against programming errors, not a business rule. The amount-above-$0 rule, with `InvalidAmount`, lives only in `Transfer` (FR-008, FR-028), and `TransferService` passes them only the amount of a valid `Transfer`, so the guard never changes a transfer's outcome.
- **FR-013** (FR-06, supports FR-01; DEC-10, DEC-11): `Account` MUST refuse a negative opening balance with `NegativeBalance` and the message `balance "<text>" must not be negative`, and MUST accept an opening balance of `0.00`. The same check MUST be available on `Account` as a class-level check that needs only the `Money`, so it can run when the row's account number is invalid.

**Repository ([FR-05](../../docs/solution-design/02-functional-requirements.md#fr-05-a-transfer-naming-an-account-that-is-not-loaded); supports FR-01)**

- **FR-014** (supports FR-01; DEC-11, DEC-31): `AccountRepository#add(account)` MUST add the account, and MUST raise `DuplicateAccount` with the message `account <number> appears more than once` when the number is already held, keeping the first account unchanged.
- **FR-015** (supports FR-01; DEC-12, DEC-31): `AccountRepository#include?(account_number)` MUST say whether the number is already held.
- **FR-016** (FR-05; DEC-17, DEC-31): `AccountRepository#find(account_number)` MUST return the held `Account`, or raise `UnknownAccount` with the message `account <number> is not loaded`. It MUST NOT create an account.
- **FR-017** (supports FR-01 and FR-08; DEC-26, DEC-27, DEC-31): `AccountRepository#all` MUST return the accounts in the order they were added.
- **FR-018** (DEC-03, DEC-31): `AccountRepository` MUST hold accounts in memory for one run only, MUST NOT know line numbers and MUST NOT store anything between runs.

**Applying a transfer ([FR-03](../../docs/solution-design/02-functional-requirements.md#fr-03-apply-a-transfer), [FR-04](../../docs/solution-design/02-functional-requirements.md#fr-04-a-transfer-that-would-take-an-account-below-0-and-exactly-0), [FR-05](../../docs/solution-design/02-functional-requirements.md#fr-05-a-transfer-naming-an-account-that-is-not-loaded))**

- **FR-019** (FR-03, FR-04, FR-05; DEC-13, DEC-17, DEC-18): `TransferService` MUST apply one `Transfer` against the repository in this order: find the from account, find the to account, `withdraw` from the from account, then `deposit` to the to account. It MUST let `UnknownAccount` or `InsufficientFunds` pass to its caller with both balances unchanged.
- **FR-020** (FR-03; DEC-14, DEC-18): `TransferService` MUST NOT read rows, build `TransferResult`s, log, or undo anything, and every transfer it is given MUST end fully applied or not applied at all.
- **FR-021** (FR-03; DEC-16): every `Transfer` MUST be applied on its own; two equal transfers MUST both be applied.

**Transfer results ([FR-03](../../docs/solution-design/02-functional-requirements.md#fr-03-apply-a-transfer); supports FR-08)**

- **FR-022** (FR-03; DEC-19): `TransferResult` MUST hold the line number, the row's values as written (after trimming: every field the row had, in order, so a `malformed_row` result keeps fewer or more than 3 and their number gives the field count), and either applied or exactly one reason code from `malformed_row`, `invalid_account_number`, `invalid_amount`, `same_account`, `unknown_account` and `insufficient_funds`. It is a domain result, not a data transfer object.
- **FR-023** (FR-03; DEC-06, DEC-19): a rejected `TransferResult` for a header-looking row MUST also carry the header hint `This looks like a header row; files must not have a header.`; any other result carries none.
- **FR-024** (FR-03; DEC-19, DEC-26): the six reason codes MUST be defined once in the domain, in the [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19) check order, so the summary (`002`) can list counts in that order.
- **FR-025** (FR-03; DEC-26): `TransferResult` MUST NOT format itself for the screen or the log.

**Domain errors**

- **FR-026** (FR-03 to FR-06; DEC-30): the domain MUST define exactly these errors: `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `NegativeBalance`, `UnknownAccount`, `DuplicateAccount` and `InsufficientFunds`. Each names the value or account number involved, and carries no line number and no reason code.
- **FR-027** (FR-03 to FR-06; DEC-07, DEC-30): the domain MUST own the exact message text of every domain error, as in the [message table](#domain-error-messages). Where page 2 shows a balances problem line, the domain message is exactly the text after `Line N: `, so the application layer only adds the line number, the duplicate's first line or the header hint, and never rewrites the domain text.

**Code organisation ([NFR-05](../../docs/solution-design/03-non-functional-requirements.md#nfr-05)) and cost ([NFR-02](../../docs/solution-design/03-non-functional-requirements.md#nfr-02))**

- **FR-028** (NFR-05; DEC-30): each business rule (16 digits, money format, amount above $0, different accounts, no overdraft, opening balance not negative, no duplicate account, unknown account) MUST live in exactly one place, inside the domain model it belongs to, as listed under [Key Entities](#key-entities).
- **FR-029** (NFR-05; DEC-30): the domain MUST NOT read files, print, log, read the clock or know line numbers.
- **FR-030** (NFR-05; DEC-30): names MUST be the plain domain names on page 6 and in the page 10 glossary, with no base classes, no suffixes such as `AggregateRoot` or `ValueObject`, and no domain events, factories or commands.
- **FR-031** (NFR-05; DEC-30, DEC-36): RuboCop with its default settings and `rubocop-rspec` MUST report zero offences, which sets at most 10 lines per method. Every later spec MUST keep zero offences.
- **FR-032** (NFR-05; DEC-30, DEC-37): the design reasoning MUST NOT be explained in code comments; it goes in the README (`003`). A DEC or FR ID MAY appear in a test name or a short comment where it makes the link clearer.
- **FR-033** (NFR-02; DEC-31, solution design pick 49): `find`, `include?` and `add` MUST take the same time however many accounts are held, and `all` MUST keep load order without a second list.
- **FR-034** (NFR-02; DEC-18): applying one transfer MUST take the same time however many accounts and transfers there are: two lookups, the checks, then two balance changes and nothing else. A rejected transfer MUST cost no more than an applied one and leave nothing to undo.
- **FR-035** (NFR-02): listing the accounts with `all` MUST visit each account once, so listing and adding up the total grow in proportion to the number of accounts.

**Project skeleton ([NFR-05](../../docs/solution-design/03-non-functional-requirements.md#nfr-05))**

- **FR-036** (DEC-01): the project MUST pin Ruby to the latest 3.4.x release in `.ruby-version`; the exact version is recorded by the plan.
- **FR-037** (DEC-01, DEC-36): the `Gemfile` MUST list `csv`, `bigdecimal` and `logger` for runtime and `rspec`, `simplecov`, `rubocop` and `rubocop-rspec` for development only, and no other gem; `Gemfile.lock` MUST be committed.
- **FR-038** (DEC-30, DEC-34): the code MUST live under `lib/`, in the folders `domain/`, `application/` and `infrastructure/`; this spec creates `lib/domain/` only, and a folder is added only when it holds several files. Specs MUST mirror the code, one spec file per class, in `spec/domain/`, with shared helpers (builders valid by default) in `spec/support/`.
- **FR-039** (DEC-34): `spec_helper.rb` MUST set random order and `.rspec` MUST set `--format documentation`.
- **FR-040** (DEC-36): SimpleCov MUST measure coverage on every test run, with no minimum figure that fails the run.
- **FR-041** (DEC-27, DEC-36): `.gitignore` MUST list `coverage/` and `output/`.
- **FR-042** (DEC-34): every domain rule MUST be tested once, in the spec of the class where it lives, using builders and no files; every edge case listed above MUST have a test.

### Domain error messages

Exact text, character for character. `<text>` is the value as given; `<number>` is the full account number; `<amount>` and `<balance>` are written with exactly 2 decimal places.

| Error | Raised by | Message | Where the text appears on page 2 |
|---|---|---|---|
| `InvalidAccountNumber` | `AccountNumber` | `account number "<text>" must be exactly 16 digits` | AC-01.4 line 3, AC-01.5, AC-01.6, AC-01.7 (before the header hint) |
| `InvalidAmount` | `Money`, empty | `balance is empty` / `amount is empty` | AC-01.6 (`balance`) |
| `InvalidAmount` | `Money`, more than 2 decimal places | `balance "<text>" has more than 2 decimal places` / `amount "<text>" has more than 2 decimal places` | AC-01.4 line 7 (`balance`) |
| `InvalidAmount` | `Money`, any other text | `balance "<text>" is not a valid amount` / `amount "<text>" is not a valid amount` | AC-01.5, AC-01.6, AC-01.7, AC-01.10 (`balance`) |
| `InvalidAmount` | `Transfer`, $0 or less | `amount "<text>" must be greater than 0.00` | not shown on any channel (reason code `invalid_amount` only) |
| `SameAccount` | `Transfer` | `account <number> cannot transfer to itself` | not shown (reason code `same_account` only) |
| `NegativeBalance` | `Account` | `balance "<text>" must not be negative` | AC-01.4 line 6 |
| `UnknownAccount` | `AccountRepository#find` | `account <number> is not loaded` | not shown (reason code `unknown_account` only) |
| `DuplicateAccount` | `AccountRepository#add` | `account <number> appears more than once` | AC-01.4 line 5, AC-01.10, before ` (first on line N)` |
| `InsufficientFunds` | `Account#withdraw` | `account <number> cannot pay <amount> from a balance of <balance>` | not shown (reason code `insufficient_funds` only) |

### Key Entities *(include if feature involves data)*

Names and meanings as on [page 6](../../docs/solution-design/06-components.md) and in the [page 10 glossary](../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary).

- **`AccountNumber`** (value, a Ruby `Data` record): one valid 16-digit account number, kept as text. Rule: exactly 16 digits. Error: `InvalidAccountNumber`.
- **`Money`** (value): one exact amount with at most 2 decimal places, written with exactly 2; records a written minus sign. Rule: money format. Error: `InvalidAmount`.
- **`Account`** (aggregate root): an account number and a balance that never goes below $0. Members: its number, its balance, `withdraw`, `deposit`, and the class-level opening-balance check. Rules: no overdraft; opening balance not negative. Errors: `InsufficientFunds`, `NegativeBalance`; `ArgumentError` for a deposit or withdrawal of $0 or less, a programming error.
- **`Transfer`** (value, a Ruby `Data` record): one request to move an amount from one account to another; refers to accounts by number. Rules: amount above $0, then different accounts. Errors: `InvalidAmount`, `SameAccount`.
- **`TransferResult`** (domain result): the outcome of one transfers row: line number, every field as written, applied or one reason code, and the header hint when it applies.
- **`AccountRepository`**: holds the run's accounts in memory, in load order; `add`, `include?`, `find`, `all`. Rules: no duplicate on add; unknown account on find. Errors: `DuplicateAccount`, `UnknownAccount`.
- **`TransferService`**: applies one `Transfer`, all or nothing: find both, withdraw, deposit.
- **Domain errors**: `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `NegativeBalance`, `UnknownAccount`, `DuplicateAccount`, `InsufficientFunds`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (FR-03 to FR-06): 100% of the domain outcomes in the acceptance scenarios above are checked by automated tests, and all pass.
- **SC-002** (FR-03, FR-04, FR-05): after every refused transfer in the tests, the difference in both balances and in the total of all balances is exactly $0.00.
- **SC-003** (NFR-01): after 1,000 additions and 1,000 subtractions of 25.60, the value differs from the exact result by $0.00; the five sample balances end exactly at 4820.50, 9974.40, 1550.00, 1725.60 and 48679.50, total 66750.00.
- **SC-004** (FR-03 to FR-06): every domain error message in the tests matches the [message table](#domain-error-messages) character for character, 10 of 10 rows.
- **SC-005** (NFR-05): the style checker reports 0 offences, and no method is longer than 10 lines.
- **SC-006** (NFR-05): each of the 8 business rules in FR-028 is found in exactly 1 class on design review.
- **SC-007** (NFR-02): the design review of the [time and space table](../../docs/solution-design/09-considerations.md#time-and-space) finds no lookup, add or transfer whose cost grows with the number of accounts.
- **SC-008** (NFR-05): the test suite passes in 3 runs in a row with different random seeds.

## Assumptions

- The assumptions in [`design-decisions.md`](../../docs/design-analysis/design-decisions.md#assumptions) hold; in particular money is dollars and cents in one currency, and an account number may start with 0.
- The values given to the domain are already trimmed by the readers (`002`); the domain does not trim.
- This spec has no file, clock, terminal or logger; the readers, `LoadBalances`, `ProcessDailyTransfer`, `DayResult`, the writer, the report, the logs, masking, the runner and `bin/run` are built in `002`; the README, CI and Docker in `003`.
- Out of scope, as on [page 4](../../docs/solution-design/04-scope.md#out-of-scope): several companies; storage between runs; retrying rejected transfers or any order other than file order; detecting duplicate transfers; creating accounts; header detection; check-digit validation; rounding or truncating; rollback, database transactions or sagas; streaming or chunking; masking on screen or in the output file; logging to a file or service; named options; a money gem; a coverage threshold.

## Decided in the run

Small gaps decided while writing this spec, consistent with `design-decisions.md`. Each is for the developer's review.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| 1 | The code lives under `lib/` (`lib/domain/`, later `lib/application/` and `lib/infrastructure/`) | DEC-30, DEC-34 | The decisions name the three folders but not their parent; `lib/` is Ruby's usual home for code, next to `bin/` and `spec/` | Folders at the project root; `app/` |
| 2 | `Money` messages say `balance` for an opening balance and `amount` for a transfer amount (`balance is empty`, `amount "abc" is not a valid amount`) | DEC-09, FR-01, FR-06 | Page 2 shows `balance ...` problem lines; the domain owns the message, so the word must come from the domain, not from `LoadBalances` rewriting it. How `Money` is told which is the plan's choice | One fixed word for both (would show `amount` in the balances errors); `LoadBalances` rewriting the message |
| 3 | `Money` keeps the text it was given, and messages quote that text, so `-5` stays `-5` and `-0` stays `-0` | DEC-09, DEC-12 | Page 2 quotes values as written (`"1.234"`, `"abc"`, `"12345"`) | Quoting the 2-decimal form (`"-5.00"` for `-5`) |
| 4 | Text with a point and 3 or more decimals (with or without a minus sign) gets "has more than 2 decimal places"; every other bad text gets "is not a valid amount" | DEC-09 | Matches AC-01.4 (`1.234`) and AC-01.5 (`abc`); one test of shape decides the message | A separate message for each bad form |
| 5 | The `Transfer` $0-or-less message: `amount "<text>" must be greater than 0.00` | DEC-10, DEC-19 | Page 2 shows only the reason code; a short message that names the value | `amount must be above $0` (does not name the value) |
| 6 | The `SameAccount` message: `account <number> cannot transfer to itself` | DEC-13 | Not shown on page 2; names the account | `from and to accounts are the same` |
| 7 | The `UnknownAccount` message: `account <number> is not loaded` | DEC-17 | Not shown on page 2; the domain knows no file, so it does not say "balances file" | `... is not in the balances file` |
| 8 | The `DuplicateAccount` message: `account <number> appears more than once`, the text `LoadBalances` puts before ` (first on line N)` | DEC-12, DEC-31 | Matches AC-01.4 line 5, so the domain owns that wording | A separate wording only for the guard |
| 9 | The `InsufficientFunds` message: `account <number> cannot pay <amount> from a balance of <balance>` | DEC-13 | Not shown on page 2; gives both values for a developer | Naming only the account |
| 10 | When both accounts are unknown, `UnknownAccount` names the from account, because it is looked up first | DEC-17, page 7.6 | Follows the lookup order on page 7.6 | Naming both accounts |
| 11 | The six reason codes are defined once in the domain, in DEC-19 order | DEC-19, DEC-26 | The summary (`002`) lists counts in that order; one place for the list | Each user of the codes listing them |
| 12 | Run-outcome lines marked **(derived)** are built from the FR-08 layout, AC-09.6 masking and DEC-21, where page 2 gives no full output for that criterion | DEC-21, DEC-26, DEC-29 | The brief asks for standard output, standard error and exit status in every scenario; deriving adds no behaviour | Leaving the channels unstated |
| 13 | Each single-row example on page 2 is the only row of `transfers.csv`, on line 1 | FR-03 to FR-06 | Page 2 gives the rows without line numbers | Other line numbers |
| 14 | The exact Ruby 3.4.x version is recorded by the plan, from the latest release when the plan is written | DEC-01 | The decision says "the latest 3.4.x release"; the number depends on when the plan runs | A version written into this spec |
| 15 | A `TransferResult` keeps every field of its row, in order, as written; for `malformed_row` the number of fields gives `N fields, expected 3` | DEC-19, page 2 FR-08, page 10 pick 12 | The report needs the field count and the log takes fields by position; keeping the fields gives both with no extra member | A separate field-count member; keeping only the first 3 fields (loses the count) |
| 16 | `Money` equality and comparison use the amount only, so `-0` equals `0`; the written minus sign changes only whether the value counts as negative, and a computed `Money` is negative only below 0 | DEC-09, page 6 `Money`, page 10 pick 25 | A value model is equal by content, and the content is the amount; the sign is recorded only so `-0` is refused | Equality that also compares the written sign (`-0` not equal to `0`) |
| 17 | `Account#withdraw` and `#deposit` raise `ArgumentError` for an amount of $0 or less, as the developer asked (P33); the amount-above-$0 rule with `InvalidAmount` stays in `Transfer` | DEC-18, DEC-30, FR-028 | The business rule keeps one place; the guard stops a mistake in the code from changing a balance, and a valid transfer never reaches it | No guard (a mistake would change a balance silently); `InvalidAmount` in `Account` (two places for one business rule) |

# Design decisions

This file is the single source of truth for how the solution to the [Mable back-end challenge](../challenge/MABLE_BACK_END_CODE_TEST.md) behaves and is designed. The solution design, the Spec Kit files and the code follow it. If any of them disagrees with this file, this file wins.

How to read it:

- Each decision has a stable ID (`DEC-01`, `DEC-02` and so on). Link to one as `design-decisions.md#dec-nn`.
- Each decision gives the **rule**, the **reason**, the options **rejected**, and **From**: the review findings and answers it comes from. D, J, X, C, B and S are the tabs of the review sheet, saved in [`clarifications/`](clarifications/). P-numbers (P4, P6, P7, P11, P12, P14, P15, P19) are prompts in the [design prompt log](../prompts/prompts-design-phase.md), and P27, P28, P30, P33, P34 and P35 are prompts in the [refactor prompt log](../prompts/prompts-refactor-phase.md); R1 to R3 are the questions from the independent review, answered in P14.
- A rule marked **[assistant's pick]** was decided by the AI assistant, where the developer's answers left a small detail open. Its reason and rejected options are in [To review](#to-review) or, once the developer agreed it, in [Agreed by the developer](#agreed-by-the-developer).

## Contents

1. [Scope and platform](#1-scope-and-platform): DEC-01 to DEC-03
2. [Reading the input files](#2-reading-the-input-files): DEC-04 to DEC-07
3. [Account numbers, money and rounding](#3-account-numbers-money-and-rounding): DEC-08 to DEC-10
4. [Loading the balances](#4-loading-the-balances): DEC-11 to DEC-12
5. [Applying the transfers](#5-applying-the-transfers): DEC-13 to DEC-21
6. [The runner and exit codes](#6-the-runner-and-exit-codes): DEC-22 to DEC-25
7. [Output](#7-output): DEC-26 to DEC-27
8. [Logging](#8-logging): DEC-28 to DEC-29
9. [Code design](#9-code-design): DEC-30 to DEC-33
10. [Tests and tooling](#10-tests-and-tooling): DEC-34 to DEC-36
11. [README and submission](#11-readme-and-submission): DEC-37 to DEC-38
12. [Assumptions](#assumptions)
13. [Out of scope](#out-of-scope)
14. [To review](#to-review)
15. [Agreed by the developer](#agreed-by-the-developer)

---

## 1. Scope and platform

<a id="dec-01"></a>
### DEC-01 Language, version and libraries

**Rule**
- The solution is written in Ruby and tested with RSpec.
- Ruby is pinned to the latest 3.4.x release, in `.ruby-version` and in the Dockerfile.
- Runtime code uses the Ruby standard library only. `csv` and `bigdecimal` are listed in the Gemfile, because they are bundled gems in Ruby 3.4. `logger` is listed too, ahead of it becoming a bundled gem.
- Development gems: `rspec`, `simplecov`, `rubocop` and `rubocop-rspec` ([DEC-36](#dec-36)).
- `Gemfile.lock` is committed. **[assistant's pick]**
- No money gem: amounts use the solution's own `Money` model built on `BigDecimal` ([DEC-09](#dec-09)).

**Reason:** the rubric asks for RSpec, which means Ruby. Ruby 3.4 is more widely installed on reviewers' machines than 4.0. The standard library is enough, so there are fewer things to install.

**Rejected:** Ruby 4.0 (newer, but fewer reviewers have it); a money gem (less code, but another dependency).

**From:** D1, J12, C7, D9, X5, S11.

<a id="dec-02"></a>
### DEC-02 One company, one day per run

**Rule**
- A run loads one balances file and applies one transfers file. It processes whichever files it is given.
- The files contain no company name and the program does not need one. Nothing in the code or output names a company.

**Reason:** the challenge asks for one company's balances and one day's transfers, and the files carry no company name.

**Rejected:** a library object that applies several transfer files over time; several transfer files in one run. Neither is asked for.

**From:** J11, D14, X7, D4.

<a id="dec-03"></a>
### DEC-03 Every run starts from the balances file

**Rule**
- All state is held in memory for one run. Each run starts again from the balances file, so the same two input files always give the same final balances.
- Each run writes a new output file, named with the time of the run ([DEC-27](#dec-27)).

**Reason:** an in-memory run repeats the same result by design, with no storage to manage.

**Rejected:** remembering which files or transfers were already applied, across runs. That needs storage and a way to identify a file, well beyond the challenge. The README explains what a version with storage would need ([DEC-37](#dec-37)).

**From:** J4, X6, B1.

## 2. Reading the input files

<a id="dec-04"></a>
### DEC-04 CSV format

**Rule**
- Both files are CSV with no header row. A balances row is `account number,balance`. A transfers row is `from account number,to account number,amount`.
- Files are read with Ruby's standard CSV library, which handles quoted values, Windows (CRLF) line endings and a missing final newline.
- Spaces around each value are trimmed before it is checked.
- A row with too few or too many fields is a bad row.
- A UTF-8 byte-order mark at the start of a file is ignored. **[assistant's pick]**
- If the library cannot read a file past some line (for example an unclosed quote, or bytes that are not valid text), the run stops: an error on stderr naming the line, no output CSV and exit status 1. In the transfers file, transfers applied in memory before that line are discarded, because nothing is written. In the balances file, the problems found in the rows before that line are reported too ([DEC-12](#dec-12)).

**Reason:** a standard parser already handles the awkward parts of CSV correctly. Stopping on an unreadable file avoids a half-applied day.

**Rejected:** a hand-written parser; reading the transfers file line by line so that only the broken line is rejected (more code, and it replaces the row-by-row reading in [DEC-32](#dec-32)); keeping the transfers applied before an unreadable line (a partial day).

**From:** D10, C12.

<a id="dec-05"></a>
### DEC-05 Blank lines are skipped

**Rule**
- An empty line, in either file, is skipped. It is not a row, not an error and not counted.
- A line with only spaces or tabs counts as blank. A line with only commas (for example `,,`) is a row with empty fields, so it is a bad row. **[assistant's pick]**

**Reason:** there is no point stopping a run, or rejecting anything, because of an empty line between valid rows.

**Rejected:** treating a blank line as a bad row.

**From:** D5 (cases 2 and 4).

<a id="dec-06"></a>
### DEC-06 A header row is a bad row

**Rule**
- There is no header detection. A header line is checked like any other row and fails, so it is a bad row: in the balances file it makes the file invalid ([DEC-12](#dec-12)); in the transfers file that row is rejected and the run continues ([DEC-14](#dec-14)).
- The message for such a row says: `This looks like a header row; files must not have a header.`
- The message is shown when the row is the first data row of the file and its first field is not empty and contains no digits at all (for example `account` or `from`). A mistyped account number such as `1111O34522226789`, or an empty first field, is not described as a header. In the transfers file the message follows the reason `invalid_account_number`.
- If such a row also has the wrong number of fields, its reason is `malformed_row` ([DEC-19](#dec-19)) and the header message still follows it. **[assistant's pick]**
- The README says files must have no header ([DEC-37](#dec-37)).

**Reason:** the sample files have no header, and a strict rule is simple. A clear message lets a user who added a header fix the file in seconds.

**Rejected:** detecting and skipping a header on the first line (needs a rule for recognising one, and can hide a real data error); skipping a header in the balances file only (two rules for the same thing).

**From:** C1, J5, D2, B3, P11, R2 in P14.

<a id="dec-07"></a>
### DEC-07 Line numbers

**Rule**
- Every error, report line and log line that refers to a row gives its physical line number in the file, starting at 1 and counting blank lines. **[assistant's pick]**
- A row that spans several lines (a quoted value containing a newline) is reported at the line where it starts. **[assistant's pick]**

**Reason:** the user can go straight to the line in an editor.

**Rejected:** numbering only the data rows; reporting the line where a row ends.

**From:** C2, D2, C6, X3, S5.

## 3. Account numbers, money and rounding

<a id="dec-08"></a>
### DEC-08 Account numbers

**Rule**
- An account number is exactly 16 digits (0 to 9), with nothing else in it. The same rule applies in both files.
- Account numbers are kept as text, never as integers, so leading zeros are kept.
- There is no check-digit (Luhn) check.

**Reason:** the challenge identifies accounts by a 16-digit number. Read as an integer, a number starting with 0 would lose digits and stop matching between the files. All five sample account numbers fail the Luhn check, so a check digit would reject the challenge's own file.

**Rejected:** storing account numbers as integers; a check-digit check.

**From:** D7, D8, X10.

<a id="dec-09"></a>
### DEC-09 Money and rounding

**Rule**
- Amounts and balances are held as `BigDecimal`, never as floating point, inside a `Money` model.
- A valid value is digits, optionally followed by a point and 1 or 2 digits. So `100`, `100.5`, `100.50` and `007.50` (7.50) are valid. **[assistant's pick]**
- A value with more than 2 decimal places is invalid. It is never rounded or truncated.
- A value that is empty or not a number is invalid. This includes `abc`, `100.`, `.50`, `+100`, `1e3`, `$100`, `1,000.00` and values with spaces inside. **[assistant's pick]**
- A leading minus sign makes a value negative, including `-0` and `-0.00`. A negative balance gets its own message in the balances file errors ([DEC-12](#dec-12)); a negative transfer amount is `invalid_amount` like any other bad amount ([DEC-19](#dec-19)). **[assistant's pick]**
- There is no upper limit on amounts or balances. **[assistant's pick]**
- Money is always written with exactly 2 decimal places, on screen and in the output CSV.

**Reason:** binary floating point cannot hold values such as 25.60 exactly, and a balance off by a cent fails "calculates test files accurately". Rejecting instead of rounding never changes the amount the company asked for.

**Rejected:** floating point; rounding half-up or to even; truncating; accepting any format Ruby can parse (it allows exponents and a leading `+`).

**From:** D9, J9, D2, S1, S2, S3.

<a id="dec-10"></a>
### DEC-10 Zero

**Rule**
- A transfer amount must be greater than $0, so `0` and `0.00` are invalid amounts.
- An opening balance of `0.00` is valid. **[assistant's pick]**

**Reason:** a transfer of nothing is not a transfer. A balance may end a transfer at exactly $0.00 ([DEC-13](#dec-13)), so $0.00 is a normal balance.

**Rejected:** allowing zero transfers; treating a zero opening balance as invalid.

**From:** Page 3 of the handwritten analysis, X5, D11.

## 4. Loading the balances

<a id="dec-11"></a>
### DEC-11 What makes the balances file invalid

**Rule**

The balances file is invalid when any of these is true:

- it has no data rows (it is empty, or holds only blank lines);
- a row does not have exactly 2 fields;
- an account number breaks [DEC-08](#dec-08);
- a balance is empty, not a number, has more than 2 decimal places ([DEC-09](#dec-09)) or is negative;
- an account number appears more than once, whether the balances are the same or different.

**Reason:** every transfer depends on the opening balances, so doubtful balances must not be used.

**Rejected:** running with no accounts when the file is empty (every transfer would fail as unknown); for a duplicate, letting the last row win (hides an error) or adding the balances together (guesses what was meant).

**From:** D2, D5 (case 1), D7, J6, J7, J8, J9.

<a id="dec-12"></a>
### DEC-12 An invalid balances file stops the run

**Rule**
- Every row is checked, and every problem is reported as an error on stderr, each with its line number ([DEC-07](#dec-07)). A row with several problems reports each one, all with the same line number. **[assistant's pick]**
- Then the run stops: no transfer is applied, the transfers file is not processed, no output file is written and the exit status is 1.
- A duplicate account is reported on the line where it repeats, naming the line where it first appeared. The repository rejects the duplicate ([DEC-31](#dec-31)); the balances loader only remembers where each account first appeared, to add that line to the message.
- Before checking a row's balance, the balances loader asks the repository whether the account number is already there (`include?`, [DEC-31](#dec-31)). If it is, the duplicate is reported, naming the line where the account first appeared.
- If the first copy of an account is itself an invalid row, it was never added, so the duplicate is reported only after that row is fixed. This is a known gap; the run stops either way.

**Reason:** the user can fix every problem in one go, and nothing runs on doubtful balances.

**Rejected:** stopping at the first bad row (one fix per run); loading the valid rows and skipping the bad ones (transfers touching skipped accounts would then fail as unknown); reporting a duplicate without the first line.

**From:** C2, C10, J8, D2, D15, S4, P19, Page 2 of the handwritten analysis.

## 5. Applying the transfers

<a id="dec-13"></a>
### DEC-13 What makes a transfer valid, and the $0 rule

**Rule**

A transfer is applied only when all of these are true:

- the row has exactly 3 fields;
- both account numbers follow [DEC-08](#dec-08);
- the from and to accounts are different;
- the amount is valid ([DEC-09](#dec-09)) and greater than $0 ([DEC-10](#dec-10));
- both accounts are in the balances file ([DEC-17](#dec-17));
- the from account's balance minus the amount is $0.00 or more.

A transfer that leaves exactly $0.00 is applied: with $100.00 in account A, a transfer of $100.00 from A is applied.

**Reason:** the challenge says money cannot be transferred if it would put the balance **below** $0, so reaching exactly $0 is allowed.

**Rejected:** treating a balance of exactly $0 after the transfer as "not enough balance".

**From:** Page 3 of the handwritten analysis, D11, D6, J1.

<a id="dec-14"></a>
### DEC-14 A bad transfer is rejected and the run continues

**Rule**
- A transfer that breaks any rule in [DEC-13](#dec-13) is rejected with a reason ([DEC-19](#dec-19)). Its balances are not changed, and the next transfer is processed.

**Reason:** one bad row should not block the rest of the company's day.

**Rejected:** stopping the whole run on a bad transfer.

**From:** Page 3 of the handwritten analysis, D2.

<a id="dec-15"></a>
### DEC-15 One pass, in file order

**Rule**
- Transfers are applied once each, in file order. A rejected transfer is not retried, even if a later transfer would have paid enough into the account.

**Reason:** simple and predictable, and the file's order is the order the company intends.

**Rejected:** retrying rejected transfers after the first pass (results depend on retry rules and are harder to explain and test); any other order, such as credits first (changes the meaning of the file).

**From:** J2, D3.

<a id="dec-16"></a>
### DEC-16 No duplicate check

**Rule**
- Every row is a separate transfer. Two rows with the same from account, to account and amount are both applied.

**Reason:** two equal payments between the same accounts on one day are realistic, and a bank treats each row as a transfer.

**Rejected:** rejecting exact repeats (blocks real payments); warning about exact repeats; rejecting a repeated from/to pair whatever the amount.

**From:** J3.

<a id="dec-17"></a>
### DEC-17 Unknown accounts

**Rule**
- An unknown account is a valid 16-digit account number that is not in the balances file.
- A transfer whose from or to account is unknown is rejected. Accounts are never created.

**Reason:** simple, and the total of all balances stays the same.

**Rejected:** creating an unknown to account with $0 (invents accounts the company never provided); stopping the whole run (one bad row blocks the day).

**From:** J1, D6.

<a id="dec-18"></a>
### DEC-18 Each transfer is all or nothing

**Rule**
- Every check and lookup is done before any balance changes: both accounts are found, then the withdrawal checks the balance before changing it, and only then the deposit, which cannot fail for a valid transfer, is made.
- So a transfer is either fully applied or not applied at all. A rejected transfer leaves both balances unchanged.
- An account refuses a deposit or withdrawal of $0 or less as a programming error ([DEC-30](#dec-30)). This guard never decides a transfer's outcome: a transfer whose amount is not above $0 is rejected as `invalid_amount` before any account is found ([DEC-19](#dec-19)).

**Reason:** in one in-memory run, checking before changing is enough to make each transfer atomic, with nothing to undo.

**Rejected:** a rollback mechanism, database transactions or sagas (machinery for a problem that cannot happen here; the README lists them as production options).

**From:** X13, Page 4 of the handwritten analysis, P33.

<a id="dec-19"></a>
### DEC-19 Transfer results and rejection reasons

**Rule**
- Each transfer produces a `TransferResult`: applied, or rejected with its reason code. It is the application's record of each row's outcome, with the row's line number and its values as written, kept for the report and the log. The summary counts are the results grouped by reason code ([DEC-26](#dec-26)).
- Every rejected transfer has exactly one reason code: the first check it fails, in this order. **[assistant's pick]**

  | Order | Reason code | When |
  |---|---|---|
  | 1 | `malformed_row` | The row does not have exactly 3 fields |
  | 2 | `invalid_account_number` | The from or to account number is not exactly 16 digits |
  | 3 | `invalid_amount` | The amount is empty, not a number, has more than 2 decimals, or is $0 or less |
  | 4 | `same_account` | The from and to accounts are the same |
  | 5 | `unknown_account` | The from or to account is not in the balances file |
  | 6 | `insufficient_funds` | The from account's balance would go below $0 |

**Reason:** each rejection says why, and counting by reason gives clearer feedback at little cost.

**Rejected:** counting only applied and rejected.

**From:** X8, Page 4 of the handwritten analysis, P35.

<a id="dec-20"></a>
### DEC-20 An empty transfers file stops the run

**Rule**
- A transfers file with no data rows (empty, or only blank lines) is an error: a message on stderr, no output file and exit status 1. The balances file is still checked first ([DEC-12](#dec-12)).

**Reason:** an empty transfers file is almost certainly the wrong file.

**Rejected:** treating it as a valid day with nothing to do.

**From:** D5 (case 3), C3, J7.

<a id="dec-21"></a>
### DEC-21 Every transfer rejected

**Rule**
- When the transfers file has rows but every one is rejected, including a file holding only a header row, the run is still a completed run: exit status 0, the output CSV is written with the balances unchanged, and the report lists every row as rejected with its reason.
- The report and the log also show: `All transfers were rejected; check this is the right file.`
- The warning is logged at warn level. In the report it comes after the summary, before the final balances. **[assistant's pick]**

**Reason:** the file was read and every row was dealt with, so the run did its job, but the user is warned that something is probably wrong.

**Rejected:** treating it like an empty file (exit 1).

**From:** C3, P4 in the design prompt log.

## 6. The runner and exit codes

<a id="dec-22"></a>
### DEC-22 Command line

**Rule**

The program starts from `bin/run`, which takes positional arguments:

| Arguments | Meaning |
|---|---|
| none | Balances `data/mable_account_balances.csv`, transfers `data/mable_transactions.csv`, output in the default place ([DEC-27](#dec-27)) |
| 2 | Balances file, transfers file; output in the default place |
| 3 | Balances file, transfers file, output file |
| 1, or 4 or more | A usage message on stderr, exit status 1 |

- `data/` holds copies of the two sample files from `docs/challenge/`, which are kept unchanged.
- `-h` and `--help` are a single argument like any other, so they show the usage message and exit with 1. **[assistant's pick]**
- Paths given as arguments are relative to the current directory. The default paths are relative to the project root, so `bin/run` works from any directory. **[assistant's pick]**

**Reason:** positional arguments are the simplest way to pass two or three files, and running with no arguments lets a reviewer try the sample at once.

**Rejected:** named options such as `--balances`; reading the sample files straight from `docs/challenge/`.

**From:** D15, J10, C4, D13, S9.

<a id="dec-23"></a>
### DEC-23 Missing or unreadable files

**Rule**
- If an input file is missing or cannot be read, the program prints a clear error on stderr, writes no output and exits with status 1.
- Both input files are checked for existence before anything is read, and every missing file is reported. **[assistant's pick]**
- Every problem found by the checks at the start, a missing input file or an output file that already exists ([DEC-25](#dec-25)), is reported together, one error line each, before the run stops.

**Reason:** the user gets a clear message instead of a stack trace.

**Rejected:** letting Ruby's own error reach the user.

**From:** D15, D2, P19.

<a id="dec-24"></a>
### DEC-24 Total of all balances is checked

**Rule**
- After the transfers, the program checks that the total of all balances equals the total before them. If it does not, the run stops with an error on stderr and no output file, and the report is not printed.
- This failure exits with status 1, like every other run that stops. **[assistant's pick]**
- With correct code this failure cannot happen, so its error path is tested with a fake repository whose total changes. The test checks the error message, that no output file is written, that no report is printed, and exit status 1 ([DEC-34](#dec-34)).

**Reason:** a transfer moves money between accounts, so the total never changes. A run-time check is a safety net if a later change breaks that. Testing the error path keeps it from being an untested branch.

**Rejected:** checking the total only in tests; a separate class for the check with an injected total (one more class); leaving the error path untested.

**From:** X9, D13, R1 in P14, Page 4 of the handwritten analysis.

<a id="dec-25"></a>
### DEC-25 Exit codes

**Rule**
- Exit status 0: the run completed, even if some or all transfers were rejected.
- Exit status 1: the run stopped. That is: wrong arguments, a missing or unreadable input file, an invalid balances file, an empty transfers file, a file the CSV library cannot read past some line, a failed total check, an output file that already exists, or an output file that cannot be written.
- If the output file already exists, the run stops with an error on stderr. The existing file is not changed.
- The output file is checked for existence at the start of the run, together with the input files. **[assistant's pick]**
- If the output file cannot be written (for example the path is a folder, or permission is denied), the run stops and the report is not printed. **[assistant's pick]**

**Reason:** a script can tell a stopped run from a completed one, and a rejected transfer is a normal part of a day. An existing file is never overwritten.

**Rejected:** a non-zero exit when some transfers are rejected; overwriting an existing output file.

**From:** D15, C3, C4, D13, C12, P6.

## 7. Output

<a id="dec-26"></a>
### DEC-26 Screen report

**Rule**

The report is printed on stdout once, at the end of a completed run, after the output CSV has been written. In this order it shows:

1. each transfer in file order: line number, applied or rejected, from account, to account, amount, and the reason if rejected;
2. a summary: the number of transfers processed (data rows, not blank lines; a header row counts), applied and rejected, the count per rejection reason, and the total of all balances before and after;
3. the warning from [DEC-21](#dec-21), when every transfer was rejected;
4. the final balances of all accounts, in the order they were loaded, each account's opening balance (before the day's transfers) next to its closing balance; an account with no applied transfer shows the same opening and closing balance;
5. the path of the output CSV.

- Account numbers are shown in full. They are masked only in the logs ([DEC-29](#dec-29)).
- The reason is shown as its reason code ([DEC-19](#dec-19)), for example `insufficient_funds`. **[assistant's pick]**
- The output path is shown relative to the folder the command was run from, or in full if the file is outside that folder. This holds for a typed path and for the default path.
- A header row in the transfers file counts as processed and rejected. **[assistant's pick]**
- The final balances are a table under the title `Final balances`: a header row `Account`, `Opening`, `Closing`, then one row per account. Each column is as wide as its widest value or heading, with two spaces between columns; account numbers are left-aligned and amounts right-aligned, so the decimal points line up. **[assistant's pick]**
- The output CSV holds only the closing balances ([DEC-27](#dec-27)).
- The rest of the exact layout is set in the solution design.

**Reason:** "runs and provides feedback" is a rubric item. Full account numbers let the user check the result against the input files by eye. The opening balance next to the closing balance lets the user check the day without opening the balances file.

**Rejected:** listing only the rejected transfers; leaving out the balances because they are in the output CSV; showing only the closing balances; a balance after each transfer line; masking account numbers on screen; showing the output path as typed or relative to the project root (wrong when the command is run from another folder); always showing the full path (long).

**From:** C6, J10, X8, X2, S6, P4, R3 in P14, Page 4 of the handwritten analysis, P28.

<a id="dec-27"></a>
### DEC-27 Output CSV of final balances

**Rule**
- A completed run writes the final balances to a new CSV file, so the next day's run can use it as its balances file.
- By default the file is `output/final_balances_YYYY-MM-DD_HHMMSS.csv`, named with the date and time the run started.
- The date and time are the computer's local time, with a 24-hour clock (for example `final_balances_2026-11-07_143005.csv`). **[assistant's pick]**
- A third argument is the full path of the output file and is used as given, with nothing added.
- An existing file is never overwritten ([DEC-25](#dec-25)). The file is created only if it does not already exist, checked at the moment it is opened as well as at the start. **[assistant's pick]**
- If writing fails partway, the partial file is deleted. **[assistant's pick]**
- Missing folders on the output path are created.
- The format is exactly that of the balances input file: no header, two columns (account number, balance), full account numbers, balances with exactly 2 decimal places, in the order the accounts were loaded.
- Nothing is written when the run stops ([DEC-25](#dec-25)).
- `output/` is listed in `.gitignore`. **[assistant's pick]**

**Reason:** the next day's run starts from today's result, and every run keeps its own file, so no result is ever lost and two runs never collide.

**Rejected:** overwriting one fixed file; a date-only name (a second run on the same day would collide); a `--force` option; treating a no-argument run differently.

**From:** D13, X1, J10, B1, S7, S8, P6, P7.

## 8. Logging

<a id="dec-28"></a>
### DEC-28 Logger

**Rule**
- Logging uses Ruby's standard `Logger`, writing to stderr. Every line has a timestamp, in `Logger`'s default format and local time. **[assistant's pick]**
- The logger is passed in (injected) to the class that processes the day's transfers, so logging can later go to a file or a logging service without changing that class. Tests pass in a logger that writes to memory.
- What is logged, and at which level:
  - info: the run start; each applied transfer (line number, masked from and to accounts, amount); the run end, with the counts per rejection reason;
  - warn: each rejected transfer with its reason code; the warning from [DEC-21](#dec-21). A rejected transfer's line gives the same details as an applied one (line number, masked from and to accounts, amount), then its reason code; fields the row does not have are left out. **[assistant's pick]**
  - error: one line saying why the run stopped, for example `Run stopped: balances file invalid: 3 problems`, with no account numbers.
- The level comes from the `LOG_LEVEL` environment variable, which accepts only `warn` and `info`, in any letter case. The default is warn, and any other value falls back to warn. The logger has no other settings.
- When the run stops, the full error message (every problem, with line numbers and full account numbers) is printed on stderr as plain text, not through the logger.

**Reason:** the system moves money, so logs matter, but a thin layer is enough here. With warn as the default, a terminal shows the report plus only rejections and errors. The user needs full details to fix a file, while the log keeps account numbers out.

**Rejected:** logging to a file or a logging service now (over-engineering for this challenge); info as the default level (a log line for every transfer mixed into the report); a `--verbose` option; accepting every `Logger` level name; sending the full error message through the logger with masked numbers.

**From:** X3, X8, C5, C9, C11, S10.

<a id="dec-29"></a>
### DEC-29 Masking account numbers

**Rule**
- Account numbers are masked in the logs only. They are shown in full on screen and in the output CSV.
- A masked account number shows its last 4 digits after 12 asterisks: `************6789`. This form is used everywhere masked numbers appear, including the solution design, the README and the tests.
- An account value that is not a valid account number is masked the same way: every character except the last 4 becomes an asterisk, and a value of 4 characters or fewer is shown as `****`. **[assistant's pick]**

**Reason:** the last 4 digits are enough to match a log line to an account without exposing the number. Full numbers on screen let the user check the result.

**Rejected:** masking on screen (harder to check by eye); a hash (cannot be matched by eye).

**From:** X2, X3, C6, P6.

## 9. Code design

<a id="dec-30"></a>
### DEC-30 Light domain-driven design

**Rule**
- The rules live inside the models:
  - `AccountNumber`: exactly 16 digits;
  - `Money`: exact amounts with `BigDecimal`, at most 2 decimal places;
  - `Transfer`: the accounts are different and the amount is above zero;
  - `Account`: no overdraft, and a deposit or withdrawal of $0 or less is a programming error that raises `ArgumentError` ([DEC-18](#dec-18));
  - the repository: no duplicate on add, unknown account on find ([DEC-31](#dec-31)).
- Class and file names are plain domain words such as `Account`, `Money` and `Transfer`. There are no base classes, no suffixes such as `AggregateRoot` or `ValueObject`, and no domain events, factories or commands.
- The code is organised in three folders: `domain`, `application` and `infrastructure`. A new folder is added only when it holds several files.
- A value that is equal to another with the same data, and never changes, is a Ruby `Data` record: `AccountNumber` and `Transfer` in the domain; `TransferResult`, the day's result and the parameter object of the class that runs the day in the application; and the row a file reader gives in the infrastructure. `Money` keeps its own equality, which ignores how the amount was written.
- The class that runs the day takes the run time as a constructor argument, defaulting to the current time. **[assistant's pick]** `bin/run` passes no run time; tests pass a fixed time so the output file name is known.
- The runner reads the clock once. When no output path is given, it gets the default path for that time from the output writer ([DEC-27](#dec-27)), checks it at the start, and passes the same run time and output path to the class that runs the day.
- The class that runs the day takes its six parts (the balances reader, the transfers reader, the output writer, the repository, the report printer and the logger) as one parameter object that names each part.
- The balances reader, the transfers reader, the output writer, the repository, the report printer and the logger are all passed in to the class that runs the day. The runner builds the real ones; tests pass fakes. The class that runs the day prints the report through the report printer after the output file is written ([DEC-26](#dec-26)).
- The errors are named for what went wrong:
  - raised by the domain models: `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `NegativeBalance`, `UnknownAccount`, `DuplicateAccount` and `InsufficientFunds`;
  - errors that stop the run: `InvalidBalancesFile`, `NoTransfers`, `UnreadableFile`, `TotalChanged` and `OutputNotWritable`.
- The design reasoning is explained in the README, not in the code.

**Reason:** the rubric asks for domain models that hold their own logic and for separation of concerns. Light DDD keeps the thinking without the ceremony. Passing the time in keeps the tests independent of the clock. A parameter object names each part where it is built and where it is read, and stays within RuboCop's default limit on parameters. A `Data` record gives equality by data and a value that cannot change, with no equality or freezing written by hand. An amount of $0 or less can reach an account only through a mistake in the code, so the account stops it with Ruby's own error rather than a domain error.

**Rejected:** full DDD terms and structure (heavy for a small program); tests stubbing `Date.today` or `Time.now` (tests would depend on internals); a `RUN_DATE` environment variable (a second setting); seven keyword parameters (over the default limit); the six parts collected in `**parts` and read through a list of names (the constructor does not name its parts); equality, `hash` and freezing written by hand in each value class (more code for the same behaviour); no amount check in `Account` (a mistake in the code would change a balance silently).

**From:** X5, D12, B4, P19, P30, P33, P34.

<a id="dec-31"></a>
### DEC-31 In-memory repository

**Rule**
- A thin in-memory repository holds the accounts and is the one place for these rules:
  - `add` rejects a duplicate account;
  - `include?` tells whether an account number is already there, so the balances loader can report a duplicate before checking a row's balance ([DEC-12](#dec-12)); **[assistant's pick]** for the name
  - `find` raises an unknown-account error, which the transfer step turns into a rejected transfer with the reason `unknown_account`;
  - `all` returns the accounts in the order they were loaded, for the report and the output CSV.
- The repository does not know line numbers. The balances loader adds them to the duplicate-account message ([DEC-12](#dec-12)).

**Reason:** the rules stay in one place; otherwise the balances loader and the transfer step would each need to handle them.

**Rejected:** no repository, with the accounts in a plain collection passed around (the rules would be spread out).

**From:** X4, C10, P19.

<a id="dec-32"></a>
### DEC-32 Reading large files

**Rule**
- The transfers file is read one row at a time with Ruby's CSV library (`CSV.open`, one row per `shift`), so the physical line number of each row is kept ([DEC-07](#dec-07)). The balances file is read in full, because all its errors must be found before any transfer runs ([DEC-12](#dec-12)).
- There is no other work for large files: no chunking, memory limits or background processing.

**Reason:** reading row by row costs nothing extra and already copes with a larger file. A day's transfers for one company are small.

**Rejected:** streaming, chunking or background processing (complexity with no stated need; the README lists very large files as a production item).

**From:** X12.

<a id="dec-33"></a>
### DEC-33 Updated high-level design

**Rule**
- The handwritten high-level design is the developer's first analysis. The solution design includes an updated high-level design based on these decisions.

**Reason:** the first sketch has no parts for validation, rejection reasons, the summary or logging.

**Rejected:** keeping the handwritten design as the final one.

**From:** D12.

## 10. Tests and tooling

<a id="dec-34"></a>
### DEC-34 Test approach

**Rule**
- Unit specs test each rule once, at the level where it belongs, using small builders that are valid by default. Every case listed in D2 is tested this way.
- Fixture files are used only for file-level behaviour: blank lines, a header row, a byte-order mark, an unreadable CSV (such as an unclosed quote), an empty file, a missing file, a wrong number of fields, and an account number with leading zeros matched across both files.
- Four end-to-end runs check the whole program (report, output CSV and exit status): the sample files, a file with mixed rejections, an all-rejected file and an invalid balances file.
- The spec folder mirrors the code: `spec/domain/`, `spec/application/` and `spec/infrastructure/`, one spec file per class. End-to-end specs are in `spec/acceptance/`. Fixture files are in `spec/fixtures/`, with copies of the challenge's files in `spec/fixtures/sample/`. Shared helpers are in `spec/support/`.
- `spec_helper.rb` sets random order, and `.rspec` sets `--format documentation`.
- Tests also cover: a transfer that leaves exactly $0.00 ([DEC-13](#dec-13)); a rejected transfer leaving both balances unchanged ([DEC-18](#dec-18)); the default log level, `LOG_LEVEL=info` and an unknown value falling back to warn ([DEC-28](#dec-28)); a duplicate account message naming both lines ([DEC-12](#dec-12)); the header message ([DEC-06](#dec-06)); the output file name from a fixed run time, and an existing output file stopping the run and staying unchanged ([DEC-27](#dec-27), [DEC-25](#dec-25)); masked numbers appearing as `************6789` ([DEC-29](#dec-29)); the failed total check, using a fake repository whose total changes ([DEC-24](#dec-24)); the output path shown relative to the folder the command was run from, and in full when outside it ([DEC-26](#dec-26)).
- An end-to-end test runs `bin/run` with 1 argument and checks the usage message on stderr and exit status 1 ([DEC-22](#dec-22)). **[assistant's pick]**

**Reason:** the rubric asks for orthogonal tests that explain the functionality. Testing each rule once, where it lives, gives good coverage without overlap.

**Rejected:** a fixture file per case with an end-to-end run for each (every rule tested twice); a fixture per case that checks only the exit status.

**From:** D2, B2, B4, X5, D3, D11, X13, C5, C6, C10, P6, R1 and R3 in P14.

<a id="dec-35"></a>
### DEC-35 Expected results for the sample files

**Rule**

Applying the sample transfers in file order, all four are applied, and the final balances are:

| Account | Opening balance | Final balance |
|---|---:|---:|
| 1111234522226789 | 5000.00 | 4820.50 |
| 1111234522221234 | 10000.00 | 9974.40 |
| 2222123433331212 | 550.00 | 1550.00 |
| 1212343433335665 | 1200.00 | 1725.60 |
| 3212343433335755 | 50000.00 | 48679.50 |
| **Total** | **66750.00** | **66750.00** |

The end-to-end test on the sample files checks these exact values.

**Reason:** the rubric checks that the program "calculates test files accurately". The sample data triggers no rejection, so the rejection rules are tested with the solution's own tests ([DEC-34](#dec-34)).

**Rejected:** none.

**From:** D3.

<a id="dec-36"></a>
### DEC-36 Quality tooling

**Rule**
- SimpleCov reports test coverage. The README shows the figure, and the `coverage/` folder is in `.gitignore`.
- There is no minimum coverage that fails the build. **[assistant's pick]**
- RuboCop runs with its default settings and `rubocop-rspec`. Every offence is fixed before submission.
- A GitHub Actions workflow runs RSpec and RuboCop on every push.
- A Dockerfile is a fallback, not the main way to run the program. It uses the official Ruby image matching `.ruby-version`, copies the project in, runs `bundle install`, and by default runs `bin/run` on the sample files. It is tested from a clean checkout before submission.

**Reason:** a coverage report is evidence for "has good coverage", and RuboCop enforces short, readable methods. Docker helps a reviewer who has no Ruby 3.4 or cannot get `bundle install` working.

**Rejected:** a coverage threshold (a rule nobody asked for); Docker as the main way to run.

**From:** X11, C7, S11.

## 11. README and submission

<a id="dec-37"></a>
### DEC-37 README

**Rule**

The README gives:

- build, test and run instructions: the normal way first (`bundle install`, then `bin/run`), then Docker as the alternative, with the commands for running the program and the tests in the container;
- on Windows, running the program as `ruby bin/run`; with Docker, mounting the `output` folder so the CSV stays on the user's machine, and setting `TZ`, because the container uses UTC for the file name; **[assistant's pick]**
- that files must have no header ([DEC-06](#dec-06));
- the `LOG_LEVEL` setting and its two values ([DEC-28](#dec-28)), and what exit statuses 0 and 1 mean ([DEC-25](#dec-25)); **[assistant's pick]**
- the assumptions ([Assumptions](#assumptions));
- the design reasoning ([DEC-30](#dec-30));
- what a version with persistent storage would need to stay idempotent, and that remembering applied files across runs is out of scope ([DEC-03](#dec-03));
- production items: handling very large files ([DEC-32](#dec-32)), and database transactions and sagas ([DEC-18](#dec-18));
- the prerequisites: the tools needed, with the versions and how to check them, and how to install Ruby 3.4 on macOS, Linux and Windows;
- a troubleshooting section for the problems a reviewer is likely to hit when installing and running the program, mostly on Windows.

**Reason:** the README is where a reviewer looks first, and these are the questions they are most likely to ask.

**Rejected:** explaining the design in code comments.

**From:** J4, X6, X5, X11, X12, X13, B3, S12, P27.

<a id="dec-38"></a>
### DEC-38 Submission

**Rule**
- The solution is submitted as a link to the GitHub repository, made public or shared with the reviewer at submission time.

**Reason:** the reviewer sees the code, the commit history and the GitHub Actions results in one place.

**Rejected:** a zip of the repository.

**From:** C8.

---

<a id="assumptions"></a>
## Assumptions

| Assumption | Reason |
|---|---|
| The balances file lists every account of the company. | Transfers to or from any other account are rejected as unknown ([DEC-17](#dec-17)). |
| The order of rows in the transfers file is the order the company intends. | Transfers are applied in file order ([DEC-15](#dec-15)). |
| Money is in dollars and cents, with no other currency. | The challenge uses $ only, and amounts have at most 2 decimal places ([DEC-09](#dec-09)). |
| One transfers file holds one day's transfers. | The challenge accepts "a day's transfers in a CSV file" ([DEC-02](#dec-02)). |
| An account number may start with 0. | The challenge says only "16 digit number", so leading zeros are kept ([DEC-08](#dec-08)). |
| The "test files" in the rubric are the two sample CSV files. | Their exact expected results are checked ([DEC-35](#dec-35)); reviewers' own files are covered by the rejection rules. |
| The program is run from the command line by one person. | The rubric asks that it "runs and provides feedback"; no web service or concurrent use is described ([DEC-22](#dec-22)). |
| The input files are UTF-8 text. | CSV files from spreadsheets and editors are UTF-8 by default; anything else is unreadable ([DEC-04](#dec-04)). |
| A day's transfers fit in memory. | One company's daily transfers are small ([DEC-32](#dec-32)). |
| The reviewer has Ruby 3.4, or Docker. | Docker is the fallback for anyone without Ruby 3.4 ([DEC-36](#dec-36)). |

<a id="out-of-scope"></a>
## Out of scope

| Item | Reason |
|---|---|
| Several companies, or a configurable company name | The challenge is for a single company, and the files carry no company name ([DEC-02](#dec-02)). |
| Persistent storage, and remembering applied files or transfers across runs | Each run starts from the balances file, which repeats the same result by design ([DEC-03](#dec-03)). |
| Retrying rejected transfers, or any order other than file order | Results would depend on retry rules and be harder to explain ([DEC-15](#dec-15)). |
| Detecting duplicate transfers | Two equal payments on one day are realistic ([DEC-16](#dec-16)). |
| Creating accounts that are not in the balances file | It would invent accounts the company never provided ([DEC-17](#dec-17)). |
| Header detection | Headers are not part of the format, and a clear message is given instead ([DEC-06](#dec-06)). |
| Check-digit validation of account numbers | The challenge requires only 16 digits, and the sample numbers fail the Luhn check ([DEC-08](#dec-08)). |
| Rounding or truncating amounts | It would change the amount the company asked for ([DEC-09](#dec-09)). |
| A rollback mechanism, database transactions or sagas | Checking before changing makes each transfer atomic in memory ([DEC-18](#dec-18)). |
| Streaming, chunking or memory limits for large files | A day's transfers for one company are small ([DEC-32](#dec-32)). |
| Masking account numbers on screen or in the output CSV | The user needs full numbers to check the result ([DEC-29](#dec-29)). |
| Logging to a file or a logging service | Over-engineering for this challenge; the injected logger allows it later ([DEC-28](#dec-28)). |
| Named command-line options, a `--force` option or a help option | Positional arguments are enough, and every run writes its own file ([DEC-22](#dec-22), [DEC-27](#dec-27)). |
| A money gem | The `Money` model on `BigDecimal` is enough ([DEC-01](#dec-01)). |
| A coverage threshold | Not asked for; the coverage figure is reported instead ([DEC-36](#dec-36)). |

<a id="to-review"></a>
## To review

| Decision | Pick | Reason | Rejected |
|---|---|---|---|
| [DEC-31](#dec-31) | The repository's membership method is named `include?` | It is Ruby's usual name for a membership question, as on `Hash` and `Array` | `exists?`, `has_account?` |
| [DEC-26](#dec-26) | The final balances are a table with the headings `Account`, `Opening` and `Closing`, each column as wide as its widest value or heading, amounts right-aligned, two spaces between columns, under the title `Final balances` | Right-aligned amounts line up their decimal points, so an account's two balances, and the balances of different accounts, can be compared by eye; the headings say which balance is which; two spaces match the rest of the report; the title still names what the output file holds | Values two spaces apart with no padding (amounts of different widths do not line up); left-aligned amounts; a table with borders; a new title such as `Balances` |

<a id="agreed-by-the-developer"></a>
## Agreed by the developer

Assistant's picks the developer has reviewed and agreed. Where the developer changed a pick, the decision shows the developer's version.

| Decision | Pick | Reason | Rejected | Agreed in |
|---|---|---|---|---|
| [DEC-01](#dec-01), [DEC-36](#dec-36) | `Gemfile.lock` is committed; SimpleCov has no minimum | An application pins its gems; a coverage threshold would add a rule nobody asked for | Not committing the lock file; a coverage threshold | S11 |
| [DEC-04](#dec-04) | A UTF-8 byte-order mark is ignored | Spreadsheet programs often add one, and the first account number would otherwise fail for no visible reason | Treating the first row as bad; stripping it by hand | P12 |
| [DEC-05](#dec-05) | Whitespace-only lines are blank; comma-only lines are bad rows | A whitespace-only line has no data and is invisible in an editor; a line of commas is a row with its values missing | The opposite for either | P12 |
| [DEC-06](#dec-06) | The header message is shown for the first data row when its first field is not empty and contains no digits at all | A header name has no digits, while a mistyped account number still has most of its digits; an empty field is missing data, not a header | Showing it whenever the first field contains a letter (would describe a mistyped account number as a header); counting an empty field as a header | P11, P14 |
| [DEC-06](#dec-06) | A header-looking first row with the wrong number of fields gets `malformed_row`, and the header message still follows it | The reason follows the check order in [DEC-19](#dec-19); the message still helps the user fix the file | Always giving a header row `invalid_account_number` (breaks the check order); leaving out the header message | P15 |
| [DEC-07](#dec-07) | Physical line numbers, counting blank lines | The user can go straight to the line in an editor | Numbering only data rows | P12 |
| [DEC-07](#dec-07) | A row spanning several lines is reported at the line where it starts | That is where the user finds it | The line where it ends | S5 |
| [DEC-09](#dec-09) | The exact text format of a valid value, including `+100`, `1e3`, `$100` and `1,000.00` being invalid | A strict format makes every accepted value unambiguous | Accepting any format Ruby can parse; requiring exactly 2 decimals | P12 |
| [DEC-09](#dec-09) | `007.50` is valid; `100.` and `.50` are invalid | A digit must appear on both sides of the point; leading zeros do not change the value | Rejecting leading zeros; accepting a bare point | S1 |
| [DEC-09](#dec-09) | `-0` and `-0.00` are negative, so invalid | A minus sign never appears in valid money | Reading them as zero | S2 |
| [DEC-09](#dec-09) | No upper limit on amounts or balances | `BigDecimal` is exact at any size, and the challenge sets no limit | An arbitrary maximum | S3 |
| [DEC-10](#dec-10) | An opening balance of $0.00 is valid | A transfer may leave exactly $0.00, so it is a normal balance | Treating it as invalid | P12 |
| [DEC-12](#dec-12) | A row with several problems reports each one, with the same line number | Every problem is reported (C2) | Only the first problem in a row | S4 |
| [DEC-19](#dec-19) | The six reason codes and the order of the checks | The checks run from the row's shape, to its values, to the accounts' state, so the most basic problem is given | A code per field problem; listing every failed check | P12 |
| [DEC-21](#dec-21) | The all-rejected warning is logged at warn and comes after the summary | Warn shows by default; next to the summary it explains the counts | Info level; at the top of the report | P12 |
| [DEC-22](#dec-22) | Typed paths are relative to the current directory; defaults to the project root | A typed path means what it means in the user's shell; a default should work from anywhere | Everything relative to one place | P12 |
| [DEC-22](#dec-22) | `-h` and `--help` show the usage message and exit with 1 | This adds no new option | A separate help option exiting with 0 | S9 |
| [DEC-23](#dec-23) | Both input files are checked for existence first | The user fixes both paths at once | Checking the transfers file only after the balances are loaded | P12 |
| [DEC-24](#dec-24) | A failed total check exits with status 1 | One meaning for exit status 1 | A separate exit status | P12 |
| [DEC-25](#dec-25) | The output file is checked for existence at the start of the run | The user learns at once that the run cannot complete | Checking only when writing | P12 |
| [DEC-25](#dec-25) | An output file that cannot be written stops the run, with no report | The output is the next day's balances file, so the run has not done its job | Printing the report and exiting with 0 | P12 |
| [DEC-26](#dec-26) | The report shows reason codes | One word per reason across report, summary and logs | A separate sentence per reason | P12 |
| [DEC-26](#dec-26) | A transfers header row counts as processed and rejected | It is a data row under C1 | Leaving it out of the counts | S6 |
| [DEC-27](#dec-27) | Local time with a 24-hour clock in the file name | The files carry no date, and this sorts the files in time order | UTC (a run just after local midnight would carry yesterday's date) | P12 |
| [DEC-27](#dec-27) | The output file is created only if it does not exist, checked when it is opened | No-overwrite holds even when two runs overlap | Relying on the start-of-run check alone | S7 |
| [DEC-27](#dec-27) | A partly written output file is deleted | Otherwise the rerun would stop on "file exists" | Leaving the partial file | S8 |
| [DEC-27](#dec-27) | `output/` is in `.gitignore` | Run output does not belong in the repository | Committing sample output | P12 |
| [DEC-27](#dec-27) | Missing folders on the output path are created | A user should not have to create the folder first | Failing when the folder is missing | P6 |
| [DEC-27](#dec-27) | A third argument is the full output path, used as given | An explicit path means the user has chosen the file name | Treating it as a folder for the dated file | P7 |
| [DEC-28](#dec-28) | Log timestamps use `Logger`'s default format, in local time | Standard, with nothing to configure | A custom format | S10 |
| [DEC-28](#dec-28) | A rejected transfer's warn line has the line number, masked accounts and amount, then the reason code; missing fields are left out | The line can be matched to the row; X3 asks for each rejection with its reason, with account numbers masked | Only the line number and reason code; logging missing fields as empty values | P15 |
| [DEC-29](#dec-29) | Masked numbers show 12 asterisks and the last 4 digits | The last 4 digits are enough to match a log line to an account | Showing the first digits too; a hash | P6 |
| [DEC-29](#dec-29) | Invalid account values are masked the same way as valid ones | A mistyped account number is still mostly a real one | Logging invalid values in full | P12 |
| [DEC-30](#dec-30) | The class that runs the day takes the run time, not only the date | The default file name includes the time ([DEC-27](#dec-27)), so a date alone is not enough to know it in tests | Passing only the date | P12 |
| [DEC-34](#dec-34) | An end-to-end test for a wrong number of arguments (usage message, exit status 1) | The usage message and exit status are only seen when `bin/run` itself runs, and no other test covers them | Testing the argument check only in a unit spec; no test | P15 |
| [DEC-37](#dec-37) | The README explains `LOG_LEVEL` and the exit statuses | A user cannot find an environment variable or the exit statuses from the report | Leaving them to be found in the code | P15 |
| [DEC-37](#dec-37) | README notes for Windows, Docker output and the time zone | These are the questions a reviewer is most likely to hit | Leaving them out | S12 |

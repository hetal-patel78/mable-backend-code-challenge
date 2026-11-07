# 2. Functional requirements

What the program must do, as nine requirements (FR-01 to FR-09), each with acceptance criteria that give exact input and exact output.

## How to read the acceptance criteria

- Each criterion is written as **Given** (the input), **When** (the command), **Then** (what must happen).
- **Standard output** (stdout) is where the program prints its report. **Standard error** (stderr) is where it prints error messages and log lines. They are shown separately. "(nothing)" means the stream stays empty.
- The **exit status** is the number the program returns to the shell: 0 means the run completed, 1 means it stopped ([DEC-25](../design-analysis/design-decisions.md#dec-25)).
- Every run starts at 2026-11-07 14:30:05 local time, from the project root, with the default log level (warn: only warnings and errors are logged) unless a criterion says otherwise. The default output file is then `output/final_balances_2026-11-07_143005.csv`.
- A CSV file (comma-separated values) is a text file with one record per line and commas between the values.
- Log lines use Ruby's standard log format. `<timestamp>` stands for the date and time to the microsecond and `<pid>` for the process number, which change on every run.
- Every file path in a message or log line is shown the same way as the output path in the report: relative to the folder the command was run from, or in full if the file is outside it (assistant's pick).
- Most criteria use this balances file, `balances.csv`, with a total of 150.00:

```
1111234522226789,100.00
1212343433335665,50.00
0000123412341234,0.00
```

- Unless a criterion says otherwise, the command is `bin/run balances.csv transfers.csv`. Where a criterion shows only some lines of the report, the rest follows the layout in [FR-08](#fr-08-the-end-of-day-result-and-its-output).

---

## FR-01 Load the balances file

The program must load every account and its starting balance from the balances file, and must stop the run, listing every problem, if the file is invalid.

Decisions: [DEC-04](../design-analysis/design-decisions.md#dec-04), [DEC-05](../design-analysis/design-decisions.md#dec-05), [DEC-06](../design-analysis/design-decisions.md#dec-06), [DEC-07](../design-analysis/design-decisions.md#dec-07), [DEC-08](../design-analysis/design-decisions.md#dec-08), [DEC-09](../design-analysis/design-decisions.md#dec-09), [DEC-10](../design-analysis/design-decisions.md#dec-10), [DEC-11](../design-analysis/design-decisions.md#dec-11), [DEC-12](../design-analysis/design-decisions.md#dec-12), [DEC-31](../design-analysis/design-decisions.md#dec-31).

**AC-01.1 A valid file is loaded, including leading zeros and a $0.00 balance.**
- Given `balances.csv` above and a transfers file with one valid row.
- When the program runs.
- Then the final balances section lists all three accounts in file order, with `0000123412341234` kept as written (leading zeros are not lost) and its balance `0.00` accepted.

**AC-01.2 Common CSV forms are accepted.**
- Given a balances file that starts with a UTF-8 byte-order mark (an invisible marker some editors add), uses Windows line endings, has no final newline, quotes a value and has spaces around values: `"1111234522226789", 100.00 `.
- When the program runs.
- Then the account is loaded as `1111234522226789` with balance `100.00`, exactly as if the line were `1111234522226789,100.00`.

**AC-01.3 Blank lines are skipped but still counted in line numbers.**
- Given a balances file whose line 2 is empty and whose line 3 holds only spaces.
- When the program runs.
- Then neither line is an error or an account, and the row on line 4 is reported as line 4 in any message.

**AC-01.4 An invalid file reports every problem and stops the run.**
- Given this balances file (line 2 is empty):

```
1111234522226789,5000.00

12345,100.00
1212343433335665,abc,9
1111234522226789,10.00
2222123433331212,-5.00
3212343433335755,1.234
```

- When the program runs.
- Then stdout is (nothing), no transfer is read or applied, no output file is written, the exit status is 1, and stderr is:

```
Error: the balances file is invalid (5 problems):
  Line 3: account number "12345" must be exactly 16 digits
  Line 4: expected 2 fields, found 3
  Line 5: account 1111234522226789 appears more than once (first on line 1)
  Line 6: balance "-5.00" must not be negative
  Line 7: balance "1.234" has more than 2 decimal places
E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 5 problems
```

**AC-01.5 A row with several problems reports each one, in field order.** (Field order is the assistant's pick.)
- Given a balances file whose line 1 is `12345,abc`.
- When the program runs.
- Then the problem lines are `Line 1: account number "12345" must be exactly 16 digits` and `Line 1: balance "abc" is not a valid amount`, the count is `(2 problems)`, and the exit status is 1.

**AC-01.6 Other balance problems.** Each of these rows on line 2 gives the problem line shown, and the exit status is 1:

| Row on line 2 | Problem line |
|---|---|
| `1111234522226789,` | `Line 2: balance is empty` |
| `1111234522226789,abc` | `Line 2: balance "abc" is not a valid amount` |
| `1111234522226789,5000.00,x` | `Line 2: expected 2 fields, found 3` |
| `,` | `Line 2: account number "" must be exactly 16 digits` and `Line 2: balance is empty` |

When a row has the wrong number of fields, only the field-count problem is reported for it, because it is not known which value is which. (Assistant's pick.)

**AC-01.7 A header row makes the file invalid, with a hint.**
- Given a balances file whose line 1 is `account,balance`.
- When the program runs.
- Then the exit status is 1 and the problem lines are:

```
  Line 1: account number "account" must be exactly 16 digits. This looks like a header row; files must not have a header.
  Line 1: balance "balance" is not a valid amount
```

A mistyped account number such as `1111O34522226789` on line 1 gets only the 16-digit message, with no header hint, because it contains digits ([DEC-06](../design-analysis/design-decisions.md#dec-06)). A header-looking line 1 with the wrong number of fields gives `Line 1: expected 2 fields, found 3. This looks like a header row; files must not have a header.` (assistant's pick, following the transfers rule in DEC-06).

**AC-01.8 An empty balances file stops the run.**
- Given a balances file `empty.csv` that is empty or holds only blank lines.
- When `bin/run empty.csv transfers.csv` runs.
- Then stdout is (nothing), the exit status is 1, and stderr is:

```
Error: the balances file has no rows: empty.csv
E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
```

(The log line wording for an empty balances file is the assistant's pick: it counts as an invalid balances file under [DEC-11](../design-analysis/design-decisions.md#dec-11).)

**AC-01.9 A balances file that cannot be read past a line.**
- Given a balances file `bad.csv` whose line 3 is `12345,100.00` and whose line 7 opens a quote that is never closed.
- When `bin/run bad.csv transfers.csv` runs.
- Then stdout is (nothing), the exit status is 1, and stderr is:

```
Error: the balances file is invalid (2 problems):
  Line 3: account number "12345" must be exactly 16 digits
  Line 7: cannot read bad.csv from this line. Check for an unclosed quote or characters that are not text.
E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
```

(The wording of the unreadable-line problem inside the balances message, and counting it as one problem, are the assistant's pick.)

**AC-01.10 A duplicate account is reported even when its balance is invalid.**
- Given a balances file whose line 1 is `1111234522226789,5000.00` and whose line 2 is `1111234522226789,abc`.
- When the program runs.
- Then the exit status is 1, the count is `(2 problems)`, and the problem lines are:

```
  Line 2: account 1111234522226789 appears more than once (first on line 1)
  Line 2: balance "abc" is not a valid amount
```

(The duplicate comes first because it belongs to the account number, following the field order in AC-01.5; assistant's pick.)

Known gap: when the first copy of an account is the row with the invalid balance, that account was never loaded, so the later copy is not yet seen as a duplicate. With line 1 `1111234522226789,abc` and line 2 `1111234522226789,10.00`, the only problem line is `Line 1: balance "abc" is not a valid amount`. The duplicate on line 2 is reported once line 1 is fixed. The run stops either way.

---

## FR-02 Read the transfers file

The program must read the transfers file one row at a time, in file order, give each row its physical line number, and handle an empty file, a file where every row is rejected and a file that cannot be read.

Decisions: [DEC-04](../design-analysis/design-decisions.md#dec-04), [DEC-05](../design-analysis/design-decisions.md#dec-05), [DEC-06](../design-analysis/design-decisions.md#dec-06), [DEC-07](../design-analysis/design-decisions.md#dec-07), [DEC-20](../design-analysis/design-decisions.md#dec-20), [DEC-21](../design-analysis/design-decisions.md#dec-21), [DEC-32](../design-analysis/design-decisions.md#dec-32).

**AC-02.1 Blank lines are skipped; a row with the wrong number of fields is rejected and the run continues.**
- Given `balances.csv` and this `transfers.csv` (lines 2 and 3 are blank; in the test, line 3 holds only spaces):

```
1111234522226789,1212343433335665,10.00


1111234522226789,1212343433335665
1212343433335665,1111234522226789,5.00
```

- When the program runs.
- Then the exit status is 0, the summary shows `Processed: 3`, `Applied: 2`, `Rejected: 1` and `malformed_row: 1`, and the transfers section is:

```
Transfers
  Line 1  applied  1111234522226789 -> 1212343433335665  10.00
  Line 4  rejected  malformed_row: 2 fields, expected 3
  Line 5  applied  1212343433335665 -> 1111234522226789  5.00
```

- And stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 4 rejected: ************6789 -> ************5665 malformed_row
```

In the log line of a row with the wrong number of fields, the fields are taken by position (from, to, amount); fields the row does not have are left out, and fields after the third are not logged. (Assistant's pick.)

**AC-02.2 A line of commas is a row with empty fields.** (Showing an empty value as `""` is the assistant's pick.)
- Given `balances.csv` and a `transfers.csv` whose line 1 is `,,`.
- When the program runs.
- Then the row is rejected, the transfers line is `  Line 1  rejected  "" -> ""  ""  invalid_account_number`, the report shows the all-rejected warning, and stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** "" invalid_account_number
W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
```

**AC-02.3 A header row is rejected with a hint; every row rejected gives a warning but still completes.**
- Given `balances.csv` and a `transfers.csv` holding only `from,to,amount`.
- When the program runs.
- Then the exit status is 0, the output file is written with the balances unchanged, and stdout is:

```
Transfers
  Line 1  rejected  from -> to  amount  invalid_account_number: This looks like a header row; files must not have a header.

Summary
  Processed: 1
  Applied: 0
  Rejected: 1
    invalid_account_number: 1
  Total before: 150.00
  Total after: 150.00

Warning: All transfers were rejected; check this is the right file.

Final balances
  1111234522226789  100.00
  1212343433335665  50.00
  0000123412341234  0.00

Output file: output/final_balances_2026-11-07_143005.csv
```

- And stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** amount invalid_account_number
W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
```

A header-looking line 1 with the wrong number of fields, such as `from,to`, gives `  Line 1  rejected  malformed_row: 2 fields, expected 3. This looks like a header row; files must not have a header.` (Joining the two with ". " is the assistant's pick.)

**AC-02.4 An empty transfers file stops the run.**
- Given `balances.csv` and a transfers file `empty.csv` that is empty or holds only blank lines.
- When `bin/run balances.csv empty.csv` runs.
- Then stdout is (nothing), no output file is written, the exit status is 1, and stderr is:

```
Error: the transfers file has no transfers: empty.csv
E, [<timestamp> #<pid>] ERROR -- : Run stopped: transfers file has no transfers
```

- And if the balances file is also invalid, only the balances error from [FR-01](#fr-01-load-the-balances-file) is shown, because the balances file is checked first.

**AC-02.5 A transfers file that cannot be read past a line stops the run, discarding earlier transfers.**
- Given `balances.csv` and a `bad.csv` whose line 1 is a valid transfer and whose line 2 opens a quote that is never closed.
- When `bin/run balances.csv bad.csv` runs.
- Then the transfer on line 1 is discarded, stdout is (nothing), no output file is written, the exit status is 1, and stderr is:

```
Error: cannot read bad.csv from line 2. Check for an unclosed quote or characters that are not text.
E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
```

Any warn lines for rows rejected before line 2 appear above these lines.

---

## FR-03 Apply a transfer

The program must apply a valid transfer by taking the amount from the from account and adding it to the to account, all or nothing, and must record each transfer as applied or rejected with exactly one reason.

Decisions: [DEC-13](../design-analysis/design-decisions.md#dec-13), [DEC-14](../design-analysis/design-decisions.md#dec-14), [DEC-16](../design-analysis/design-decisions.md#dec-16), [DEC-18](../design-analysis/design-decisions.md#dec-18), [DEC-19](../design-analysis/design-decisions.md#dec-19).

**AC-03.1 A valid transfer moves the money.**
- Given `balances.csv` and a `transfers.csv` of `1111234522226789,1212343433335665,30.00`.
- When the program runs.
- Then the exit status is 0, stderr is (nothing), and stdout contains:

```
  Line 1  applied  1111234522226789 -> 1212343433335665  30.00
...
Final balances
  1111234522226789  70.00
  1212343433335665  80.00
  0000123412341234  0.00
```

**AC-03.2 A rejected transfer changes nothing and the run continues.**
- Given any transfer rejected for any of the six reasons in AC-03.3.
- When the program runs.
- Then both accounts keep their balances, the next row is processed, and the run ends with exit status 0.

**AC-03.3 Each rejected transfer has exactly one reason: the first check it fails, in this order.**

| Order | Reason code | When |
|---|---|---|
| 1 | `malformed_row` | the row does not have exactly 3 fields |
| 2 | `invalid_account_number` | the from or to account number is not exactly 16 digits |
| 3 | `invalid_amount` | the amount is empty, not a number, has more than 2 decimals, or is $0 or less |
| 4 | `same_account` | the from and to accounts are the same |
| 5 | `unknown_account` | the from or to account is not in the balances file |
| 6 | `insufficient_funds` | the from account's balance would go below $0 |

For example, with `balances.csv`:
- `12345,1212343433335665,abc` is rejected as `invalid_account_number`, not `invalid_amount`;
- `1111234522226789,1111234522226789,0` is rejected as `invalid_amount`, not `same_account`;
- `9999888877776666,9999888877776666,5.00` is rejected as `same_account`, not `unknown_account`.

---

## FR-04 A transfer that would take an account below $0, and exactly $0

The program must reject a transfer that would leave the from account below $0.00, and must apply one that leaves it at exactly $0.00.

Decisions: [DEC-13](../design-analysis/design-decisions.md#dec-13), [DEC-10](../design-analysis/design-decisions.md#dec-10), [DEC-19](../design-analysis/design-decisions.md#dec-19).

**AC-04.1 Below $0 by one cent is rejected, with both balances unchanged.**
- Given `balances.csv` and a `transfers.csv` of `1111234522226789,1212343433335665,100.01`.
- When the program runs.
- Then the exit status is 0, the balances stay 100.00, 50.00 and 0.00, stdout contains `  Line 1  rejected  1111234522226789 -> 1212343433335665  100.01  insufficient_funds`, and stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds
W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
```

**AC-04.2 Exactly $0 is applied.**
- Given `balances.csv` and a `transfers.csv` of `1111234522226789,1212343433335665,100.00`.
- When the program runs.
- Then the transfer is applied, stderr is (nothing), and the final balances are `1111234522226789  0.00`, `1212343433335665  150.00` and `0000123412341234  0.00`.

**AC-04.3 An account already at $0.00 cannot pay anything.**
- Given `balances.csv` and a `transfers.csv` of `0000123412341234,1111234522226789,0.01`.
- When the program runs.
- Then it is rejected as `insufficient_funds` and the balances are unchanged.

---

## FR-05 A transfer naming an account that is not loaded

The program must reject a transfer whose from or to account is a valid 16-digit number that is not in the balances file, and must never create an account.

Decisions: [DEC-17](../design-analysis/design-decisions.md#dec-17).

**AC-05.1 Unknown to account.**
- Given `balances.csv` and a `transfers.csv` of `1111234522226789,9999888877776666,10.00`.
- When the program runs.
- Then the exit status is 0, stdout contains `  Line 1  rejected  1111234522226789 -> 9999888877776666  10.00  unknown_account`, the final balances list only the three loaded accounts, unchanged, and stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************6666 10.00 unknown_account
W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
```

**AC-05.2 Unknown from account.**
- Given `balances.csv` and a `transfers.csv` of `9999888877776666,1111234522226789,10.00`.
- When the program runs.
- Then it is rejected as `unknown_account` and no balance changes.

---

## FR-06 Validation of account numbers and amounts

The program must accept only account numbers of exactly 16 digits, kept as text, and only amounts in the exact money format, never rounding them.

Decisions: [DEC-08](../design-analysis/design-decisions.md#dec-08), [DEC-09](../design-analysis/design-decisions.md#dec-09), [DEC-10](../design-analysis/design-decisions.md#dec-10), [DEC-19](../design-analysis/design-decisions.md#dec-19).

**AC-06.1 Account numbers.** Given `balances.csv` and a transfer from the value below to `1212343433335665` for `10.00`, when the program runs, then:

| From value | Result |
|---|---|
| `1111234522226789` | applied |
| `0000123412341234` | rejected `insufficient_funds` (the leading zeros match the balances file) |
| `111123452222678` (15 digits) | rejected `invalid_account_number` |
| `11112345222267890` (17 digits) | rejected `invalid_account_number` |
| `1111O34522226789` (letter O) | rejected `invalid_account_number` |
| `1111-2345-2222-6789` | rejected `invalid_account_number` |

There is no check-digit check: all five sample account numbers are accepted.

**AC-06.2 Amounts.** Given `balances.csv` and a transfer from `1111234522226789` to `1212343433335665` with the amount below, when the program runs, then:

| Amount as written | Result |
|---|---|
| `10`, `10.5`, `10.50`, `007.50` | applied, shown as `10.00`, `10.50`, `10.50`, `7.50` |
| `0`, `0.00` | rejected `invalid_amount` (must be above $0) |
| `-5.00`, `-0`, `-0.00` | rejected `invalid_amount` (negative) |
| `1.234` | rejected `invalid_amount` (never rounded) |
| empty, `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0` | rejected `invalid_amount` |
| `"1,000.00"` (quoted) | rejected `invalid_amount` |
| `1,000.00` (not quoted) | rejected `malformed_row`, because the comma makes 4 fields |

A rejected line shows the values as written in the file, after trimming spaces: `10.` is shown as `10.`, not `10.00`.

An applied amount is also shown with 2 decimal places in the info log line when `LOG_LEVEL=info` ([AC-09.5](#fr-09-the-runner)).

**AC-06.3 The same rules hold in the balances file.** A balance follows the amount rules above, except that `0` and `0.00` are valid and a negative balance gets its own message ([FR-01](#fr-01-load-the-balances-file)).

---

## FR-07 The order transfers are applied in

The program must apply each transfer once, in file order, never retry a rejected transfer, and treat every row as a separate transfer, even an exact repeat.

Decisions: [DEC-15](../design-analysis/design-decisions.md#dec-15), [DEC-16](../design-analysis/design-decisions.md#dec-16).

**AC-07.1 One pass, no retry, repeats applied.**
- Given `balances.csv` and this `transfers.csv`:

```
0000123412341234,1212343433335665,20.00
1111234522226789,0000123412341234,20.00
1111234522226789,0000123412341234,20.00
```

- When the program runs.
- Then line 1 is rejected as `insufficient_funds` and is not retried, even though lines 2 and 3 later pay 40.00 into that account; lines 2 and 3 are both applied; the exit status is 0; and the final balances are:

```
Final balances
  1111234522226789  60.00
  1212343433335665  50.00
  0000123412341234  40.00
```

---

## FR-08 The end-of-day result and its output

At the end of a completed run, the program must check that the total of all balances has not changed, write the final balances to a new CSV file, and then print the report on stdout.

Decisions: [DEC-24](../design-analysis/design-decisions.md#dec-24), [DEC-26](../design-analysis/design-decisions.md#dec-26), [DEC-27](../design-analysis/design-decisions.md#dec-27), [DEC-35](../design-analysis/design-decisions.md#dec-35).

### Report layout

The report has five parts, in this order, separated by one empty line. Within a line, two spaces separate the parts. Money is always written with 2 decimal places.

1. `Transfers`: one line per data row, in file order: `Line N`, `applied` or `rejected`, `from -> to`, the amount, and for a rejected row its reason code. An applied amount is written with 2 decimal places; a rejected row shows its values as written. A row with the wrong number of fields shows `malformed_row: N fields, expected 3` in place of the values. On a header-looking first row, the reason is followed by `: This looks like a header row; files must not have a header.` (or `. This looks like ...` after `malformed_row: N fields, expected 3`) ([DEC-06](../design-analysis/design-decisions.md#dec-06)).
2. `Summary`: `Processed` (data rows, including a header row), `Applied`, `Rejected`, then the count per reason code that occurred, indented under `Rejected`, in the order of [FR-03](#fr-03-apply-a-transfer), then `Total before` and `Total after`.
3. Only when every transfer was rejected: `Warning: All transfers were rejected; check this is the right file.`
4. `Final balances`: every account in the order it was loaded, with its full account number.
5. `Output file:` and the output path, relative to the folder the command was run from, or in full if the file is outside that folder.

### Acceptance criteria

**AC-08.1 The sample files give the exact expected result.**
- Given the challenge's sample files in `data/`.
- When `bin/run` runs with no arguments.
- Then the exit status is 0, stderr is (nothing), and stdout is:

```
Transfers
  Line 1  applied  1111234522226789 -> 1212343433335665  500.00
  Line 2  applied  3212343433335755 -> 2222123433331212  1000.00
  Line 3  applied  3212343433335755 -> 1111234522226789  320.50
  Line 4  applied  1111234522221234 -> 1212343433335665  25.60

Summary
  Processed: 4
  Applied: 4
  Rejected: 0
  Total before: 66750.00
  Total after: 66750.00

Final balances
  1111234522226789  4820.50
  1111234522221234  9974.40
  2222123433331212  1550.00
  1212343433335665  1725.60
  3212343433335755  48679.50

Output file: output/final_balances_2026-11-07_143005.csv
```

- And `output/final_balances_2026-11-07_143005.csv` holds exactly:

```
1111234522226789,4820.50
1111234522221234,9974.40
2222123433331212,1550.00
1212343433335665,1725.60
3212343433335755,48679.50
```

| Account | Starting balance | Closing balance |
|---|---:|---:|
| 1111234522226789 | 5000.00 | 4820.50 |
| 1111234522221234 | 10000.00 | 9974.40 |
| 2222123433331212 | 550.00 | 1550.00 |
| 1212343433335665 | 1200.00 | 1725.60 |
| 3212343433335755 | 50000.00 | 48679.50 |
| **Total** | **66750.00** | **66750.00** |

**AC-08.2 A day with mixed rejections.**
- Given `balances.csv` and this `transfers.csv`:

```
1111234522226789,1212343433335665,30.00
1111234522226789,1212343433335665,90.00
1212343433335665,9999888877776666,10.00
1111234522226789,0000123412341234,70.00
1212343433335665,1212343433335665,5.00
```

- When the program runs.
- Then the exit status is 0 and stdout is:

```
Transfers
  Line 1  applied  1111234522226789 -> 1212343433335665  30.00
  Line 2  rejected  1111234522226789 -> 1212343433335665  90.00  insufficient_funds
  Line 3  rejected  1212343433335665 -> 9999888877776666  10.00  unknown_account
  Line 4  applied  1111234522226789 -> 0000123412341234  70.00
  Line 5  rejected  1212343433335665 -> 1212343433335665  5.00  same_account

Summary
  Processed: 5
  Applied: 2
  Rejected: 3
    same_account: 1
    unknown_account: 1
    insufficient_funds: 1
  Total before: 150.00
  Total after: 150.00

Final balances
  1111234522226789  0.00
  1212343433335665  80.00
  0000123412341234  70.00

Output file: output/final_balances_2026-11-07_143005.csv
```

- And stderr is:

```
W, [<timestamp> #<pid>]  WARN -- : Line 2 rejected: ************6789 -> ************5665 90.00 insufficient_funds
W, [<timestamp> #<pid>]  WARN -- : Line 3 rejected: ************5665 -> ************6666 10.00 unknown_account
W, [<timestamp> #<pid>]  WARN -- : Line 5 rejected: ************5665 -> ************5665 5.00 same_account
```

- And the output file holds exactly:

```
1111234522226789,0.00
1212343433335665,80.00
0000123412341234,70.00
```

**AC-08.3 The output file.**
- The output file must have no header, one account per line as `account number,balance`, full account numbers, balances with exactly 2 decimal places, in load order: the same format as the balances file, so it can be the next day's balances file.
- Every line, the last one included, must end with a line feed (LF) only, on every operating system. (Assistant's pick.)
- With no third argument, it must be `output/final_balances_YYYY-MM-DD_HHMMSS.csv`, named from the local date and time the run started (24-hour clock).
- With a third argument, that path must be used as given, and any missing folders on it must be created.

**AC-08.4 The output path is shown relative to where the command was run.**
- Given the sample files.
- When `../bin/run` runs with no arguments from the project's `docs` folder.
- Then the last report line is `Output file: ../output/final_balances_2026-11-07_143005.csv`.
- And when a third argument names a file outside the current folder, such as `/tmp/day1.csv`, the last line shows the full path: `Output file: /tmp/day1.csv`.

**AC-08.5 A changed total stops the run.**
- Given the sample files and a fault that makes the total after the transfers (66749.00) differ from the total before (66750.00). With correct code this cannot happen; the test creates it on purpose.
- When the run reaches the end of the transfers.
- Then stdout is (nothing), no output file is written, the exit status is 1, and stderr is:

```
Error: the total of all balances changed from 66750.00 to 66749.00. No output file was written.
E, [<timestamp> #<pid>] ERROR -- : Run stopped: total of all balances changed
```

---

## FR-09 The runner

The program must start from `bin/run`, process one balances file and one transfers file per run, check its arguments and files before reading them, log at the level set by the `LOG_LEVEL` environment variable (a setting given to the program from the shell), and exit with 0 for a completed run and 1 for a stopped one.

Decisions: [DEC-02](../design-analysis/design-decisions.md#dec-02), [DEC-03](../design-analysis/design-decisions.md#dec-03), [DEC-22](../design-analysis/design-decisions.md#dec-22), [DEC-23](../design-analysis/design-decisions.md#dec-23), [DEC-25](../design-analysis/design-decisions.md#dec-25), [DEC-28](../design-analysis/design-decisions.md#dec-28), [DEC-29](../design-analysis/design-decisions.md#dec-29).

**AC-09.1 Arguments.**

| Command | Balances | Transfers | Output |
|---|---|---|---|
| `bin/run` | `data/mable_account_balances.csv` | `data/mable_transactions.csv` | default name in `output/` |
| `bin/run b.csv t.csv` | `b.csv` | `t.csv` | default name in `output/` |
| `bin/run b.csv t.csv out/day1.csv` | `b.csv` | `t.csv` | `out/day1.csv` |

Typed paths are relative to the current folder. The default paths are relative to the project root, so `bin/run` with no arguments works from any folder.

**AC-09.2 Wrong number of arguments.**
- Given any folder.
- When `bin/run` runs with 1 argument, or with 4 or more, including `bin/run -h` and `bin/run --help`.
- Then stdout is (nothing), no file is read or written, the exit status is 1, and stderr is exactly:

```
Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
With no arguments, runs the sample files in data/.
```

**AC-09.3 Start checks are reported together.**
- Given that neither `missing1.csv` nor `missing2.csv` exists, and `out/day1.csv` already exists.
- When `bin/run missing1.csv missing2.csv out/day1.csv` runs.
- Then stdout is (nothing), no file is read, `out/day1.csv` is unchanged, the exit status is 1, and stderr is:

```
Error: file not found: missing1.csv
Error: file not found: missing2.csv
Error: output file already exists: out/day1.csv. Delete it or give another output path.
E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found, output file already exists)
```

- Every problem found at the start gets its own `Error:` line, in the order balances, transfers, output, followed by one log line that lists only the reasons that occurred (the order and the log wording are the assistant's pick). With only the two missing files, the log line is `Run stopped: start checks failed (file not found)`.
- With only an existing output file, such as `bin/run balances.csv transfers.csv out/day1.csv`, no transfer is read, `out/day1.csv` is unchanged, and stderr is the third `Error:` line above followed by `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)`.

**AC-09.3a An input file that cannot be opened stops the run.**
- Given `balances.csv` exists but cannot be opened (permission denied).
- When `bin/run balances.csv transfers.csv` runs.
- Then stdout is (nothing), no output file is written, the exit status is 1, and stderr is:

```
Error: cannot read file balances.csv: <reason from the system>
E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
```

The same holds for a transfers file that cannot be opened. This problem is found when the file is opened, after the start checks in AC-09.3 have passed. (The message wording, and reusing the `cannot read file` log line, are the assistant's pick.)

**AC-09.4 An output file that cannot be written stops the run.**
- Given `balances.csv`, a valid `transfers.csv`, and a third argument `out` that names an existing folder.
- When `bin/run balances.csv transfers.csv out` runs.
- Then stdout is (nothing), no file is left behind, the exit status is 1, and stderr is:

```
Error: cannot write output file out: <reason from the system>
E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot write output file
```

A path that is an existing folder gives this error, not the "already exists" error. (Assistant's pick.)

**AC-09.5 Log level.**
- Given the sample files.
- When `LOG_LEVEL=info bin/run` runs (`INFO` and `Info` work the same).
- Then stdout is the report in AC-08.1, the exit status is 0, and stderr is:

```
I, [<timestamp> #<pid>]  INFO -- : Run started: balances data/mable_account_balances.csv, transfers data/mable_transactions.csv
I, [<timestamp> #<pid>]  INFO -- : Line 1 applied: ************6789 -> ************5665 500.00
I, [<timestamp> #<pid>]  INFO -- : Line 2 applied: ************5755 -> ************1212 1000.00
I, [<timestamp> #<pid>]  INFO -- : Line 3 applied: ************5755 -> ************6789 320.50
I, [<timestamp> #<pid>]  INFO -- : Line 4 applied: ************1234 -> ************5665 25.60
I, [<timestamp> #<pid>]  INFO -- : Run ended: processed 4, applied 4, rejected 0
```

- With `LOG_LEVEL` unset, `warn`, or any other value such as `debug`, the level is warn and the sample run's stderr is (nothing).
- At info level, a run with rejections ends with, for example, `Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)`.

**AC-09.6 Account numbers are masked only in log lines.**
- Log lines must show 12 asterisks and the last 4 characters: `************6789`. A value that is not a valid account number is masked the same way (`12345` becomes `*2345`), and a value of 4 characters or fewer becomes `****`.
- The report, the error messages and the output file must show full account numbers. Error log lines must show no account numbers at all.

**AC-09.7 Every run starts from the balances file.**
- Given the sample files.
- When `bin/run` runs twice, one second apart.
- Then both runs give the same report and the same final balances, and each writes its own file (`..._143005.csv` and `..._143006.csv`). Nothing in the report, the logs or the output names a company.

**AC-09.8 Exit status.**
- 0 for every completed run, even if some or all transfers were rejected.
- 1 for every stopped run: wrong arguments, a missing or unreadable input file, an invalid balances file, an empty transfers file, a file that cannot be read past a line, a changed total, an output file that already exists, or an output file that cannot be written.

---

## Assistant's picks on this page

Small details the decisions leave open are marked "(assistant's pick)" where they appear and are listed, with their reasons, in [page 10](10-traceability-glossary-assumptions.md). The report layout and exact message wording are also assistant's picks ([DEC-26](../design-analysis/design-decisions.md#dec-26) leaves the layout to the solution design).

[Back to the solution design](README.md)

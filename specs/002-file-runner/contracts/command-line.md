# Contract: the `bin/run` command

What a user, a script or a test can rely on when it runs the program. The exact texts are the spec's ([FR-027 to FR-037](../spec.md#functional-requirements) and the [run-stopping messages table](../spec.md#run-stopping-messages)), copied from [page 2](../../../docs/solution-design/02-functional-requirements.md) and [page 9](../../../docs/solution-design/09-considerations.md#standard-output-standard-error-and-exit-codes); this page puts them in one place for the command. If this page and the spec ever differ, the spec wins.

## Invocation

```text
bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
ruby bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]      # on Windows
```

| Arguments | Balances | Transfers | Output |
|---|---|---|---|
| none | `data/mable_account_balances.csv` under the project root | `data/mable_transactions.csv` under the project root | `output/final_balances_YYYY-MM-DD_HHMMSS.csv` under the project root |
| 2 | the first, from the current folder | the second, from the current folder | as with none |
| 3 | the first | the second | the third, from the current folder, used as given |
| 1, or 4 or more (`-h` and `--help` included) | usage message, exit 1 | | |

`YYYY-MM-DD_HHMMSS` is the local date and time the run started, 24-hour clock ([DEC-27](../../../docs/design-analysis/design-decisions.md#dec-27)).

Environment: `LOG_LEVEL` is `info` (any letter case) for info level; anything else, or unset, is warn ([DEC-28](../../../docs/design-analysis/design-decisions.md#dec-28)).

## Streams

| Stream | Carries |
|---|---|
| Standard output | The report of a completed run, once, after the output file is written; nothing else, ever |
| Standard error | `Error:` lines and the usage message (plain text), and log lines (`Logger`'s default format) |

Every path in the report, in a message or in a log line is shown relative to the current folder when the file is in it or below it, and in full otherwise (DEC-26; plan P10).

## The report (exit status 0)

```text
Transfers
  Line <N>  applied  <from> -> <to>  <amount, 2 decimals>
  Line <N>  rejected  <from> -> <to>  <amount as written>  <reason code>[: <header hint>]
  Line <N>  rejected  malformed_row: <K> fields, expected 3[. <header hint>]

Summary
  Processed: <p>
  Applied: <a>
  Rejected: <r>
    <reason code>: <count>          (each reason that occurred, DEC-19 order)
  Total before: <total>
  Total after: <total>

Warning: All transfers were rejected; check this is the right file.      (only when every row was rejected, followed by an empty line)

Final balances
  Account           Opening  Closing
  <account number>  <opening>  <closing>       (each account, load order)

Output file: <path>
```

An empty value is shown as `""`. Account numbers are in full. Money has exactly 2 decimal places. In `Final balances`, `<opening>` is the balance before the day's transfers and `<closing>` the balance after them; each column is as wide as its widest value or heading, with two spaces between columns, the account number left-aligned and the amounts and their headings right-aligned (DEC-26).

## Log lines

`<L>, [<timestamp> #<pid>] <LEVEL> -- : <text>`, `Logger`'s default format, where `<L>` is the level's first letter and `<LEVEL>` the level name right-aligned in 5 characters, so a warn line starts `W, [<timestamp> #<pid>]  WARN -- : ` and an error line `E, [<timestamp> #<pid>] ERROR -- : `.

| Level | Text | When |
|---|---|---|
| info | `Run started: balances <path>, transfers <path>` | after the start checks pass |
| info | `Line <N> applied: <masked from> -> <masked to> <amount, 2 decimals>` | each applied row |
| warn | `Line <N> rejected: <masked from> -> <masked to> <amount as written> <reason code>` (fields the row does not have left out; `""` for an empty amount) | each rejected row |
| warn | `All transfers were rejected; check this is the right file.` | every row rejected |
| info | `Run ended: processed <p>, applied <a>, rejected <r>` and, when `<r>` is above 0, ` (<code> <count>, ...)` | a completed run, last |
| error | `Run stopped: <reason>` | once, for every stopped run except wrong arguments |

Masked: every character but the last 4 becomes `*`; 4 characters or fewer, or empty, is `****` ([DEC-29](../../../docs/design-analysis/design-decisions.md#dec-29)).

## Stopped runs (exit status 1)

Standard output is empty, no output file is left, and a file already at the output path is unchanged. Standard error holds the plain-text line(s), then the error log line, exactly as in the spec's [run-stopping messages table](../spec.md#run-stopping-messages):

| Situation | Plain text | `Run stopped: ` reason |
|---|---|---|
| Wrong number of arguments | `Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]` and `With no arguments, runs the sample files in data/.` | (no log line) |
| Input file missing | `Error: file not found: <path>` | `start checks failed (<reasons>)` |
| Output file already exists | `Error: output file already exists: <path>. Delete it or give another output path.` | `start checks failed (<reasons>)` |
| Input file cannot be opened | `Error: cannot read file <path>: <reason from the system>` | `cannot read file` |
| Invalid balances file | `Error: the balances file is invalid (<count>):` then `  Line <N>: <problem>` each | `balances file invalid: <count>` |
| Balances file with no rows | `Error: the balances file has no rows: <path>` | `balances file invalid: 1 problem` |
| Transfers file with no rows | `Error: the transfers file has no transfers: <path>` | `transfers file has no transfers` |
| Transfers file unreadable past a line | `Error: cannot read <path> from line <N>. Check for an unclosed quote or characters that are not text.` | `cannot read file` |
| Total changed | `Error: the total of all balances changed from <before> to <after>. No output file was written.` | `total of all balances changed` |
| Output file cannot be written | `Error: cannot write output file <path>: <reason from the system>` | `cannot write output file` |

Start-check `Error:` lines come in the order balances, transfers, output; `<reasons>` lists `file not found` and `output file already exists`, each once and only if it occurred, in that order, separated by `, `. `<count>` is `1 problem` or `<n> problems`.

An unexpected error (a bug) is not caught: Ruby prints its stack trace and the exit status is 1 (page 10 pick 45).

## The output file

One line per account, `<account number>,<balance>`, full account numbers, balances with exactly 2 decimal places, in load order, no header, every line ending with LF only, the last included ([DEC-27](../../../docs/design-analysis/design-decisions.md#dec-27), page 10 pick 17). It can be the next day's balances file. Missing folders on its path are created; an existing file is never overwritten.

## Exit status

`0`: the run completed, even if some or every transfer was rejected. `1`: the run stopped ([DEC-25](../../../docs/design-analysis/design-decisions.md#dec-25)).

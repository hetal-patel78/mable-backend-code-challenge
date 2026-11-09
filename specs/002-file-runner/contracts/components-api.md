# Contract: the application and infrastructure members

The members of this spec's classes that other classes and the specs may call, with their arguments, results and errors. Anything not listed here is private. Names follow [page 6](../../../docs/solution-design/06-components.md) and the [page 10 glossary](../../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary); the members those pages leave open are decided in the [plan](../plan.md#decided-in-the-run). Every message is copied character for character from the spec's [run-stopping messages table](../spec.md#run-stopping-messages). The domain members used are exactly those of `001`'s [contract](../../001-domain/contracts/domain-api.md).

## Loading

Code files load their own dependencies with `require_relative`, and only those whose constants they name. A spec requires the file of the class it tests and of every other class it names, with `lib/` on the load path (`001` plan D13).

| File | Defines | Uses |
|---|---|---|
| `application/errors` | `InvalidBalancesFile`, `NoTransfers`, `TotalChanged` | |
| `application/load_balances` | `LoadBalances` | `domain/account_number`, `domain/money`, `domain/account`, `domain/errors`, `application/errors`, `infrastructure/errors` |
| `application/day_result` | `DayResult` | `domain/transfer_result` |
| `application/log_messages` | `LogMessages` | `domain/money` |
| `application/process_daily_transfer` | `ProcessDailyTransfer` | `application/load_balances`, `application/log_messages`, `application/day_result`, `application/errors`, `domain/account_number`, `domain/money`, `domain/errors`, `domain/transfer`, `domain/transfer_result`, `domain/transfer_service`, `infrastructure/final_balances_csv_writer` (for `default_path`) |
| `infrastructure/errors` | `UnreadableFile`, `OutputNotWritable` | `infrastructure/display_path` |
| `infrastructure/row` | `Row` | |
| `infrastructure/csv_rows` | `CsvRows` | `csv`, `infrastructure/row`, `infrastructure/errors` |
| `infrastructure/balances_csv_reader` | `BalancesCsvReader` | `infrastructure/csv_rows` |
| `infrastructure/transfers_csv_reader` | `TransfersCsvReader` | `infrastructure/csv_rows` |
| `infrastructure/display_path` | `DisplayPath` | `pathname` |
| `infrastructure/final_balances_csv_writer` | `FinalBalancesCsvWriter` | `fileutils`, `infrastructure/errors` |
| `infrastructure/report_printer` | `ReportPrinter` | `domain/money`, `application/day_result`, `infrastructure/display_path`, `infrastructure/transfers_csv_reader` |
| `infrastructure/runner` | `Runner` | `logger`, every class above, `domain/account_repository` |

## Reading

| Call | Returns or yields | Raises, with the exact message |
|---|---|---|
| `Row.new(line_number:, fields:, expected_size:, header_hint: nil)` | a `Row` | |
| `row.line_number`, `row.fields`, `row.expected_size`, `row.header_hint` | as given | |
| `row.wrong_field_count?` | `fields.size != expected_size` | |
| `CsvRows::HEADER_HINT` | `This looks like a header row; files must not have a header.` | |
| `CsvRows.new(path, expected_size).each { \|row\| }` | each non-blank `Row`, in file order | `UnreadableFile` (below) |
| `BalancesCsvReader::FIELD_COUNT` | `2` | |
| `TransfersCsvReader::FIELD_COUNT` | `3` | |
| `BalancesCsvReader.new.each_row(path) { \|row\| }` | `Row`s with `expected_size` 2 | `UnreadableFile` |
| `TransfersCsvReader.new.each_row(path) { \|row\| }` | `Row`s with `expected_size` 3 | `UnreadableFile` |

`UnreadableFile` from a reader is one of:

- `cannot read file <path>: <reason from the system>`: the file cannot be opened or read (`line_number` nil);
- `cannot read <path> from line <N>. Check for an unclosed quote or characters that are not text.`: raised after every row before line `N` has been yielded (`line_number` `N`).

## Application

| Call | Returns | Raises, with the exact message |
|---|---|---|
| `LoadBalances.new(reader, repository)` | a loader | |
| `loader.call(path)` | nil; the repository holds every account, in file order | `InvalidBalancesFile`: `the balances file is invalid (<count>):` followed by `\n  Line <N>: <problem>` per problem; or `the balances file has no rows: <path>`. `UnreadableFile` for a file that cannot be opened, unchanged |
| `ProcessDailyTransfer::Parts.new(balances_reader:, transfers_reader:, writer:, repository:, reporter:, logger:)` | the parts, a frozen `Data` value read by name | `ArgumentError` when a part is missing or a name is unknown |
| `ProcessDailyTransfer.new(parts, run_time: Time.now)` | a day | |
| `day.call(balances_path, transfers_path, output_path = nil)` | the `DayResult` | `InvalidBalancesFile`, `UnreadableFile`, `NoTransfers`: `the transfers file has no transfers: <path>`, `TotalChanged`: `the total of all balances changed from <before> to <after>. No output file was written.`, `OutputNotWritable` |
| `DayResult::ALL_REJECTED_WARNING` | `All transfers were rejected; check this is the right file.` | |
| `LogMessages.run_started(balances_path, transfers_path)` | `Run started: balances <balances path>, transfers <transfers path>` | |
| `LogMessages.applied(result)` | `Line <N> applied: <masked from> -> <masked to> <amount with 2 decimal places>` | |
| `LogMessages.rejected(result)` | `Line <N> rejected: <masked from> -> <masked to> <amount as written> <reason code>`, with only the fields the row has | |
| `LogMessages.run_ended(day_result)` | `Run ended: processed <p>, applied <a>, rejected <r>`, then ` (<code> <count>, ...)` when <r> is above 0 | |
| `LogMessages.mask(value)` | the value with every character except the last 4 as `*`, or `****` | |
| `DayResult.new(results:, total_before:, total_after:, opening_balances:, accounts:, output_path:)` | a `DayResult` | |
| `result.results`, `.total_before`, `.total_after`, `.opening_balances`, `.accounts`, `.output_path` | as given | |
| `result.processed_count`, `.applied_count`, `.rejected_count` | Integer | |
| `result.rejected_counts` | `{ reason_code => count }`, only codes that occurred, in DEC-19 order | |
| `result.all_rejected?` | Boolean | |

The `<problem>` texts inside `InvalidBalancesFile`, in field order for each row:

| Problem | Text |
|---|---|
| Wrong number of fields (only problem of its row) | `expected 2 fields, found <K>`, then `. This looks like a header row; files must not have a header.` when the row has the header hint |
| Invalid account number | `001`'s `InvalidAccountNumber` message, then `. This looks like a header row; files must not have a header.` when the row has the header hint |
| Duplicate account | `001`'s `DuplicateAccount` message, then ` (first on line <M>)` |
| Invalid balance | `001`'s `InvalidAmount` message (`balance is empty`, `balance "<text>" is not a valid amount`, `balance "<text>" has more than 2 decimal places`) |
| Negative balance | `001`'s `NegativeBalance` message |
| Unreadable line (last problem) | `cannot read <path> from this line. Check for an unclosed quote or characters that are not text.` |

## Run-stopping errors

| Call | Returns |
|---|---|
| `InvalidBalancesFile.new(problems)` | an error; `problems` returns the `Line <N>: ...` texts |
| `InvalidBalancesFile.no_rows(path)` | an error with the no-rows message |
| `NoTransfers.new(path)` | an error |
| `TotalChanged.new(before, after)` | an error; `before`, `after` return the `Money` totals |
| `UnreadableFile.cannot_open(path, error)` | an error; `path`; `line_number` nil |
| `UnreadableFile.at_line(path, line_number)` | an error; `path`; `line_number`; `line_problem` |
| `OutputNotWritable.new(path, error)` | an error |
| `error.message` | the text after `Error: ` in the spec's table |
| `error.stop_reason` | the text after `Run stopped: ` in the spec's table |

`<reason from the system>` is `error.message` of the `SystemCallError` or `IOError` up to ` @ ` (plan P9).

## Output

| Call | Returns | Raises |
|---|---|---|
| `FinalBalancesCsvWriter.default_path(run_time)` | `output/final_balances_<YYYY-MM-DD>_<HHMMSS>.csv` from `run_time`'s own (local) time | |
| `FinalBalancesCsvWriter.new.write(accounts, path)` | nil; the file holds `<account.number>,<account.balance>\n` per account | `OutputNotWritable`: `cannot write output file <path>: <reason from the system>` |
| `DisplayPath.of(path, folder = Dir.pwd)` | the path to show | |
| `ReportPrinter.new(output: $stdout, current_folder: Dir.pwd)` | a reporter | |
| `reporter.print(day_result)` | nil; the report is on `output` | |

## Runner

| Call | Returns |
|---|---|
| `Runner::STOPPING_ERRORS` | `[InvalidBalancesFile, NoTransfers, TotalChanged, UnreadableFile, OutputNotWritable]` |
| `Runner.new(stdout: $stdout, stderr: $stderr, env: ENV)` | a runner |
| `runner.run(arguments)` | `0` for a completed run, `1` for a stopped run; streams as in [command-line.md](command-line.md) |

## What the parts expect of each other

- A reader passed to `LoadBalances` or `ProcessDailyTransfer` needs only `each_row(path)` yielding `Row`s; the fake readers in the specs have the same member.
- A reporter needs only `print(day_result)`; a writer only `write(accounts, path)`; a repository `add`, `include?`, `find` and `all` (`001`); a logger `info`, `warn` and `error`.
- The `Runner` passes `ProcessDailyTransfer` the balances and transfers paths in their shown form (`DisplayPath.of`) and the output path in full (plan P11), so `DayResult#output_path` is the full path. The application classes show the paths they are given: `InvalidBalancesFile.no_rows` and `NoTransfers` in their messages, `ProcessDailyTransfer` in its `Run started` line; no `application/` file uses `DisplayPath` (page 6 pick 53). `DisplayPath.of` is used only in `infrastructure/`: by the `Runner` for its start-check lines and the paths it passes on, by `UnreadableFile` and `OutputNotWritable` in their messages, and by `ReportPrinter`, which alone works out the output path to show in the report (page 6 pick 41). The readers and the writer open files with the path they are given.

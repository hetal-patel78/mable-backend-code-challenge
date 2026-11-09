# 7.8 A missing file

The start checks: a missing input file and an existing output file are reported together, before anything is read, and the run stops.

**Example.** `bin/run data/missing.csv data/mable_transactions.csv output/day1.csv`, where `data/missing.csv` does not exist and `output/day1.csv` already exists.

```mermaid
sequenceDiagram
    actor U as User
    participant R as Runner
    participant L as Logger
    participant P as ProcessDailyTransfer
    U->>R: bin/run data/missing.csv data/mable_transactions.csv output/day1.csv
    R->>R: 3 arguments: valid
    R->>L: LOG_LEVEL not set: build the logger at warn
    R->>R: read the clock once
    R->>R: resolve the paths; the output path is the third argument
    R->>R: start checks, all together: balances, transfers, output
    Note over R: data/missing.csv does not exist, output/day1.csv exists
    R-->>U: standard error: one Error: line for each problem
    R->>L: error: Run stopped: start checks failed (file not found, output file already exists)
    Note over P: never built or run: no file is read, written or changed
    R-->>U: exit status 1
```

Standard error, in full:

```
Error: file not found: data/missing.csv
Error: output file already exists: output/day1.csv. Delete it or give another output path.
E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found, output file already exists)
```

How it works:

- The `Runner` checks both input files and the output file together, before anything is read, and prints one `Error:` line for each problem, in the order balances, transfers, output. The user can then fix every path at once ([DEC-23](../../design-analysis/design-decisions.md#dec-23), [DEC-25](../../design-analysis/design-decisions.md#dec-25)).
- The log line lists only the reasons that occurred. With only a missing file it is `Run stopped: start checks failed (file not found)`; with only an existing output file it is `Run stopped: start checks failed (output file already exists)`.
- The existing `output/day1.csv` is not changed ([DEC-25](../../design-analysis/design-decisions.md#dec-25)).
- With no third argument, the `Runner` asks `FinalBalancesCsvWriter` for the default output path for the run time it read, and checks that path the same way ([DEC-27](../../design-analysis/design-decisions.md#dec-27)). `ProcessDailyTransfer` is later given that same path, so the file checked is the file written.
- The logger is built before the start checks, so a failed start check can be logged. A wrong number of arguments is found before the logger exists, and is the only stop with no log line ([DEC-22](../../design-analysis/design-decisions.md#dec-22), [DEC-28](../../design-analysis/design-decisions.md#dec-28)).
- The start checks are done by the `Runner` itself, so no error class is raised for them. The run-stopping errors, such as `UnreadableFile`, come later, from the parts the `Runner` builds after the checks pass.
- An input file that exists but cannot be opened, for example because permission is denied, passes the start checks. It is found when the reader opens it, which raises `UnreadableFile`; the run then stops with exit status 1 ([DEC-23](../../design-analysis/design-decisions.md#dec-23)).
- `ProcessDailyTransfer` is never built, so no file is read, no report is printed and no output file is written ([DEC-23](../../design-analysis/design-decisions.md#dec-23), [DEC-25](../../design-analysis/design-decisions.md#dec-25)).

A file that exists but has no rows is not a missing file: it stops the run later, with `InvalidBalancesFile` for the balances file or `NoTransfers` for the transfers file ([DEC-11](../../design-analysis/design-decisions.md#dec-11), [DEC-20](../../design-analysis/design-decisions.md#dec-20)). The exact messages are in [Functional requirements](../02-functional-requirements.md).

[Back to the overview](README.md)
[Back to the solution design](../README.md)

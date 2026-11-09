# 7.2 Sample files end to end

The whole run on the challenge's two sample files, from `bin/run` to exit status 0.

The command is `bin/run` with no arguments, so the runner uses the copies of the sample files in `data/` and the default output path ([DEC-22](../../design-analysis/design-decisions.md#dec-22), [DEC-27](../../design-analysis/design-decisions.md#dec-27)). The flow is split in two diagrams: the runner's view, then the day's work inside `ProcessDailyTransfer`.

## The runner's view

```mermaid
sequenceDiagram
    actor U as User
    participant R as Runner
    participant W as FinalBalancesCsvWriter
    participant P as ProcessDailyTransfer
    participant RP as ReportPrinter
    U->>R: bin/run (no arguments)
    R->>R: 0 arguments: valid
    R->>R: LOG_LEVEL not set: logger at warn
    R->>R: read the clock once: 2026-11-07 14:30:05
    R->>R: use the data/ sample files, found from the project root
    R->>W: default_path for 14:30:05 (class method, no writer built yet)
    W-->>R: output/final_balances_2026-11-07_143005.csv
    R->>R: start checks: both input files exist, output file does not
    R->>P: build with the real readers, writer, repository, reporter,<br/>the logger and the run time
    R->>P: run with the balances path, transfers path and output path
    Note over P: load balances, apply 4 transfers, check the total (next diagram)
    P->>W: write 5 final balances in load order to the output path
    P->>RP: print the report from the DayResult
    RP-->>U: report on standard output
    P-->>R: DayResult
    R-->>U: exit status 0
```

## Inside the day

```mermaid
sequenceDiagram
    participant P as ProcessDailyTransfer
    participant BR as BalancesCsvReader
    participant LB as LoadBalances
    participant Repo as AccountRepository
    participant TR as TransfersCsvReader
    participant TS as TransferService
    P->>LB: load the balances with the reader and the repository it was given
    LB->>BR: read every row
    BR-->>LB: rows for lines 1 to 5, each with its line number
    LB->>Repo: for each row: include? (no), then add: 5 accounts, no problems found
    P->>Repo: all, then note each opening balance and add them up for the total before: 66750.00
    P->>TR: read the transfers file
    loop each row, in file order (lines 1 to 4)
        TR-->>P: next row with its line number
        P->>TS: apply the Transfer
        TS->>Repo: find the from and to accounts
        Note over TS: withdraw from the from Account, then deposit to the to Account
        P->>P: TransferResult applied
    end
    P->>Repo: all, then add up the total after: 66750.00, equal to the total before
```

- Both files are read one row at a time, and every row of the balances file is read and checked before any transfer is read ([DEC-32](../../design-analysis/design-decisions.md#dec-32)). Each transfer follows the flow on [page 03](03-successful-transfer.md). The total check is [DEC-24](../../design-analysis/design-decisions.md#dec-24).

## Balances after each transfer

| After | 1111234522226789 | 1111234522221234 | 2222123433331212 | 1212343433335665 | 3212343433335755 |
|---|---:|---:|---:|---:|---:|
| Loading | 5000.00 | 10000.00 | 550.00 | 1200.00 | 50000.00 |
| Line 1: 500.00 from 1111234522226789 to 1212343433335665 | 4500.00 | 10000.00 | 550.00 | 1700.00 | 50000.00 |
| Line 2: 1000.00 from 3212343433335755 to 2222123433331212 | 4500.00 | 10000.00 | 1550.00 | 1700.00 | 49000.00 |
| Line 3: 320.50 from 3212343433335755 to 1111234522226789 | 4820.50 | 10000.00 | 1550.00 | 1700.00 | 48679.50 |
| Line 4: 25.60 from 1111234522221234 to 1212343433335665 | 4820.50 | 9974.40 | 1550.00 | 1725.60 | 48679.50 |

All four transfers are applied. The last row is the closing balance of every account, as [DEC-35](../../design-analysis/design-decisions.md#dec-35) requires, and the total stays 66750.00. The output file holds these five balances in load order, and standard error stays empty at the default log level ([DEC-28](../../design-analysis/design-decisions.md#dec-28)). The exact report is in [Functional requirements](../02-functional-requirements.md); [page 09](09-run-output-and-exit-code.md) shows the order of the outputs.

[Back to the overview](README.md)
[Back to the solution design](../README.md)

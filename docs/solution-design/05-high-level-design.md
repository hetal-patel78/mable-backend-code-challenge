# 5. High-level design

Purpose: show how the program is put together, where data comes in and goes out, and where a new input format or a new transfer rule would be added.

This is the updated high-level design that replaces the developer's handwritten sketch. It adds the parts the sketch did not have: validation, rejection reasons, the summary and logging ([DEC-33](../design-analysis/design-decisions.md#dec-33)). Each component is described in full on [page 6](06-components.md); the step-by-step flows are on [page 7](07-logical-flow/README.md).

## Overview

The whole program in one diagram; the four diagrams below show each part in detail.

```mermaid
flowchart LR
    In[("Balances CSV<br/>Transfers CSV")]
    Out[("Output CSV<br/>closing balances")]
    Screen[["Screen<br/>report · errors and logs"]]

    subgraph infra["Infrastructure"]
        Run["bin/run → Runner"]
        IO["Readers · writer<br/>report printer · logger"]
    end

    subgraph app["Application"]
        PDT["ProcessDailyTransfer<br/>runs one day"]
    end

    subgraph dom["Domain"]
        TS["TransferService"]
        Models["Account · Transfer · Money<br/>AccountNumber · AccountRepository"]
    end

    Run -- "builds the parts, runs the day" --> PDT
    In --> IO
    PDT -- "rows in, results out" --> IO
    IO --> Out
    IO --> Screen
    Run -- "error messages" --> Screen
    PDT -- "each transfer" --> TS
    TS -- "find, withdraw, deposit" --> Models
```

## The three layers

The code is split into three folders ([DEC-30](../design-analysis/design-decisions.md#dec-30)):

- **Infrastructure** (`infrastructure/`): everything that touches the outside world. It reads the CSV files, writes the output file, prints the report and runs the command.
- **Application** (`application/`): runs one day. It loads the balances, applies each transfer in file order, keeps each row's outcome as a `TransferResult`, writes the output and prints the report through the parts it is given.
- **Domain** (`domain/`): the business rules. A *domain model* is a class named after a business idea, such as `Account` or `Money`, that holds its own rules. The domain knows nothing about files, line numbers, the screen or the logger.

## Diagram 1: what the Runner builds and passes in

```mermaid
flowchart LR
    Bin["bin/run"]
    Run["Runner"]
    PDT["ProcessDailyTransfer"]
    Rd["BalancesCsvReader<br/>TransfersCsvReader"]
    W["FinalBalancesCsvWriter"]
    Repo["AccountRepository"]
    RP["ReportPrinter"]
    Log["Logger"]

    Bin --> Run
    Run -- "builds; asks for the<br/>default output path" --> W
    Run -- "builds" --> Rd
    Run -- "builds" --> Repo
    Run -- "builds" --> RP
    Run -- "builds" --> Log
    Run -- "run time, output path,<br/>and every part built" --> PDT
```

*Passed in* and *repository* are defined in the [glossary](10-traceability-glossary-assumptions.md#glossary).

- `bin/run` passes only the command-line arguments. The `Runner` reads the clock once, works out and checks the output path, and passes the run time, the paths and every part it built in to `ProcessDailyTransfer`, so the checked path and the written path are always the same ([DEC-25](../design-analysis/design-decisions.md#dec-25), [DEC-27](../design-analysis/design-decisions.md#dec-27), [DEC-28](../design-analysis/design-decisions.md#dec-28), [DEC-30](../design-analysis/design-decisions.md#dec-30), [DEC-31](../design-analysis/design-decisions.md#dec-31)). The steps in order are under [`Runner` on page 6](06-components.md#runner).
- Because every part and the run time are passed in, tests pass fakes and a fixed time instead; which ones is under [`ProcessDailyTransfer` on page 6](06-components.md#processdailytransfer) ([DEC-24](../design-analysis/design-decisions.md#dec-24), [DEC-34](../design-analysis/design-decisions.md#dec-34)).

## Diagram 2: how the input files are read

```mermaid
flowchart LR
    Files[("Balances CSV<br/>Transfers CSV")]
    PDT["ProcessDailyTransfer"]
    BR["BalancesCsvReader"]
    TR["TransfersCsvReader"]
    LB["LoadBalances"]
    Repo["AccountRepository"]
    Dom["Other domain models"]

    PDT --> LB
    LB --> BR
    PDT --> TR
    BR -- "reads" --> Files
    TR -- "reads, one row at a time" --> Files
    LB --> Repo
    LB --> Dom
    PDT --> Dom
```

- The CSV files are read only in infrastructure, by the two readers. They use Ruby's CSV library, skip blank lines, trim spaces and give each row as text fields with its physical line number ([DEC-04](../design-analysis/design-decisions.md#dec-04), [DEC-05](../design-analysis/design-decisions.md#dec-05), [DEC-07](../design-analysis/design-decisions.md#dec-07)).
- The readers check only the shape of a row: the number of fields, and the hint that a first row looks like a header ([DEC-06](../design-analysis/design-decisions.md#dec-06)). Every value rule is checked in the domain.
- The balances file is read in full; the transfers file is read one row at a time ([DEC-32](../design-analysis/design-decisions.md#dec-32)).
- `LoadBalances` fills the repository that was passed in, and the repository stays the one place that knows about duplicates; how each row is checked is on [page 6](06-components.md#loadbalances) ([DEC-12](../design-analysis/design-decisions.md#dec-12), [DEC-31](../design-analysis/design-decisions.md#dec-31)).

## Diagram 3: the domain models

```mermaid
flowchart LR
    PDT["ProcessDailyTransfer<br/>(application)"]
    TS["TransferService"]
    Repo["AccountRepository"]
    Acc["Account<br/>(aggregate root)"]
    Tr["Transfer"]
    Res["TransferResult<br/>(application)"]
    AN["AccountNumber"]
    M["Money"]

    PDT -- "builds" --> Tr
    PDT -- "hands the Transfer to" --> TS
    PDT --> Res
    TS --> Repo
    TS --> Tr
    Repo --> Acc
    Acc --> AN
    Acc --> M
    Tr --> AN
    Tr --> M
```

*Aggregate root*, `BigDecimal` and *reason code* are defined in the [glossary](10-traceability-glossary-assumptions.md#glossary); here `Account` is the aggregate root that guards its balance.

Each rule lives in the model that owns the data it checks, and each model raises its own error when the rule is broken ([DEC-30](../design-analysis/design-decisions.md#dec-30)). Which error each model raises is in the [errors table on page 6](06-components.md#errors-and-who-raises-them).

| Model | Rule it guards |
|---|---|
| `AccountNumber` | exactly 16 digits, kept as text ([DEC-08](../design-analysis/design-decisions.md#dec-08)) |
| `Money` | exact amount on `BigDecimal`, at most 2 decimal places, always written with 2 ([DEC-09](../design-analysis/design-decisions.md#dec-09)) |
| `Transfer` | the two accounts differ, and the amount is above $0 ([DEC-10](../design-analysis/design-decisions.md#dec-10), [DEC-13](../design-analysis/design-decisions.md#dec-13)) |
| `Account` | the opening balance is not negative; a withdrawal must not take the balance below $0; exactly $0.00 is allowed; a deposit or withdrawal of $0 or less is a programming error ([DEC-10](../design-analysis/design-decisions.md#dec-10), [DEC-11](../design-analysis/design-decisions.md#dec-11), [DEC-13](../design-analysis/design-decisions.md#dec-13), [DEC-18](../design-analysis/design-decisions.md#dec-18)) |
| `AccountRepository` | no duplicate account on add; unknown account on find; accounts kept in load order ([DEC-31](../design-analysis/design-decisions.md#dec-31)) |

`TransferService` applies each transfer all or nothing; why the order of its steps makes that so is on [page 7.1](07-logical-flow/01-apply-one-transfer.md) ([DEC-18](../design-analysis/design-decisions.md#dec-18)). `ProcessDailyTransfer` records each transfer's outcome as a `TransferResult`, the application's record of the row: applied, or rejected with one reason code ([DEC-19](../design-analysis/design-decisions.md#dec-19)). `ProcessDailyTransfer` turns each domain error into its reason code ([DEC-19](../design-analysis/design-decisions.md#dec-19)); the mapping is in the [errors table on page 6](06-components.md#errors-and-who-raises-them). Why `Account` is the aggregate root is explained on [page 6](06-components.md).

## Diagram 4: where the results and errors go

```mermaid
flowchart LR
    PDT["ProcessDailyTransfer"]
    W["FinalBalancesCsvWriter"]
    Out[("Output CSV<br/>output/final_balances_…csv")]
    RP["ReportPrinter"]
    StdOut[["stdout: report"]]
    Run["Runner"]
    StdErr[["stderr: errors and log lines"]]

    PDT --> W --> Out
    PDT -- "DayResult" --> RP --> StdOut
    PDT -- "log lines (Logger passed in)" --> StdErr
    PDT -- "run-stopping error" --> Run
    Run -- "error message and<br/>error log line" --> StdErr
```

*stdout* and *stderr* (standard output and standard error) are defined in the [glossary](10-traceability-glossary-assumptions.md#glossary). `DayResult` holds everything the report needs about a completed run.

- **A rejected transfer is not an error that stops the run.** The reader marks a row with the wrong number of fields, or a domain model raises an error that has a reason code. `ProcessDailyTransfer` turns that into a rejected `TransferResult` with its reason code, logs it at warn level ([DEC-28](../design-analysis/design-decisions.md#dec-28)), and goes on to the next row ([DEC-14](../design-analysis/design-decisions.md#dec-14), [DEC-17](../design-analysis/design-decisions.md#dec-17), [DEC-19](../design-analysis/design-decisions.md#dec-19)).
- **Errors that stop the run go up to the `Runner`.** The five run-stopping errors, and who raises each, are in the [errors table on page 6](06-components.md#errors-and-who-raises-them). For each error that reaches it, the `Runner` prints the plain message on stderr, logs one line at error level, and exits with status 1 ([DEC-25](../design-analysis/design-decisions.md#dec-25), [DEC-28](../design-analysis/design-decisions.md#dec-28)).
- **Start checks are done by the `Runner` before the day starts:** the number of arguments, then the input and output files together ([DEC-22](../design-analysis/design-decisions.md#dec-22), [DEC-23](../design-analysis/design-decisions.md#dec-23), [DEC-25](../design-analysis/design-decisions.md#dec-25)). What each stop prints, and its exit status, is in the [exit code table on page 9](09-considerations.md#standard-output-standard-error-and-exit-codes).
- **Log lines** go to stderr through the `Logger` passed in, with account numbers masked ([DEC-28](../design-analysis/design-decisions.md#dec-28), [DEC-29](../design-analysis/design-decisions.md#dec-29)). `ProcessDailyTransfer` logs them, with the text of each line from [`LogMessages`](06-components.md#logmessages), or from `DayResult` for the all-rejected warning. What is logged at each level is in the [stream table on page 9](09-considerations.md#standard-output-standard-error-and-exit-codes).
- **The output CSV** is written by `FinalBalancesCsvWriter`, never over an existing file ([DEC-27](../design-analysis/design-decisions.md#dec-27)).
- **The report** is printed on stdout by `ProcessDailyTransfer` through the `ReportPrinter` it was given, only for a completed run; the order of the output file, the report and the exit status is on [page 7.9](07-logical-flow/09-run-output-and-exit-code.md) ([DEC-25](../design-analysis/design-decisions.md#dec-25), [DEC-26](../design-analysis/design-decisions.md#dec-26)).

The exact report layout and messages are on [page 2](02-functional-requirements.md); error handling by layer is on [page 9](09-considerations.md).

## Adding another input format

A new format, for example JSON, needs a new reader in infrastructure. It must give the same thing the CSV readers give: each row as text fields with its line number, the same row-shape checks, and `UnreadableFile` for a file it cannot read; a new transfers reader must also give one row at a time ([DEC-32](../design-analysis/design-decisions.md#dec-32)). Because the readers are passed in, the only other change is in the `Runner`, which builds the new reader instead of the CSV one. `ProcessDailyTransfer`, `LoadBalances` and the domain do not change. How the `Runner` would choose between formats, for example by file extension, is not covered by the decisions.

## Adding another transfer rule

A new rule, for example a maximum amount for a single transfer, goes into the domain model that owns the data it checks (here `Transfer`):

- a rule about one transfer's own values goes in `Transfer`;
- a rule about a balance goes in `Account`;
- a rule about which accounts exist goes in `AccountRepository`.

`TransferService` keeps its order: every check before any balance changes ([DEC-18](../design-analysis/design-decisions.md#dec-18)). A new rule also needs a new error, a new reason code and a place in the check order ([DEC-19](../design-analysis/design-decisions.md#dec-19)), and these are decisions. So a new rule must first be agreed as a new decision in [`design-decisions.md`](../design-analysis/design-decisions.md). The readers, the writer and the `Runner` do not change; `ProcessDailyTransfer` maps the new error to its reason code, and the report and the log show it like any other.

More on extensibility is on [page 9](09-considerations.md).

[Back to the solution design](README.md)

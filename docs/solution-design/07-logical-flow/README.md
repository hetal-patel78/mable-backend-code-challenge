# 7. Logical flow

How control and data move through the program, shown as one flowchart and eight pages of sequence diagrams.

A *sequence diagram* shows the components of the program as columns and the calls between them as arrows, from top to bottom in time order. The component and error names are the ones described in [Components](../06-components.md). The exact report lines and messages are owned by [Functional requirements](../02-functional-requirements.md); these pages quote them only where a flow needs them.

All examples use the run time 2026-11-07 14:30:05 (local time), run from the project root, with the default log level (warn) unless a page says otherwise.

## How a run starts

Every flow on these pages starts the same way: `bin/run` passes the arguments to the `Runner`, which checks them, builds the logger, reads the clock once, resolves the paths and runs the start checks, then builds the real parts and runs `ProcessDailyTransfer`. The steps in order, with their decisions, are under [`Runner` on page 6](../06-components.md#runner); a failed start check is on [page 08](08-missing-file.md).

## Pages

| Page | What it shows |
|---|---|
| [01. Apply one transfer](01-apply-one-transfer.md) | Flowchart: the six checks in their fixed order, all before any balance changes, and the error behind each reason ([DEC-19](../../design-analysis/design-decisions.md#dec-19), [DEC-18](../../design-analysis/design-decisions.md#dec-18)). |
| [02. Sample files end to end](02-sample-files-end-to-end.md) | The challenge's two files, from `bin/run` to the output file, the report and exit status 0 ([DEC-35](../../design-analysis/design-decisions.md#dec-35)). |
| [03. A successful transfer](03-successful-transfer.md) | One valid transfer: both accounts found, withdraw, then deposit, then an applied result. |
| [04. A transfer that would go below $0](04-insufficient-funds.md) | A transfer that would take the account below $0 is rejected and both balances stay unchanged ([DEC-13](../../design-analysis/design-decisions.md#dec-13)). |
| [05. Exactly $0](05-exactly-zero.md) | A transfer that leaves the paying account at exactly $0.00 is applied ([DEC-13](../../design-analysis/design-decisions.md#dec-13)). |
| [06. Unknown account](06-unknown-account.md) | A transfer naming an account that is not loaded is rejected; no account is created ([DEC-17](../../design-analysis/design-decisions.md#dec-17)). |
| [07. A row that cannot be read](07-unreadable-row.md) | A row with the wrong number of fields is rejected and the run continues; a file the CSV library cannot read past stops the run with `UnreadableFile` ([DEC-04](../../design-analysis/design-decisions.md#dec-04)). |
| [08. A missing file](08-missing-file.md) | The start checks: a missing input file and an existing output file are reported together, before anything is read, and the run stops ([DEC-23](../../design-analysis/design-decisions.md#dec-23), [DEC-25](../../design-analysis/design-decisions.md#dec-25)). |
| [09. Run output and exit code](09-run-output-and-exit-code.md) | What goes to the output file, standard output and standard error, in which order, which error stops a run, and the exit status ([DEC-25](../../design-analysis/design-decisions.md#dec-25), [DEC-26](../../design-analysis/design-decisions.md#dec-26)). |

[Back to the solution design](../README.md)

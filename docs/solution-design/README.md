# Solution design

How the solution to the [Mable back-end challenge](../challenge/MABLE_BACK_END_CODE_TEST.md) is built: what it must do, how it is put together, and why.

**Sources.** Every rule comes from [`design-decisions.md`](../design-analysis/design-decisions.md), cited by its ID (for example [DEC-13](../design-analysis/design-decisions.md#dec-13)). If this design and a decision ever differ, the decision wins. This design adds the detail of *how*; it does not change *what* was decided. The pages follow the developer's [brief](solution-design-brief.md).

**In one paragraph.** A command-line program loads one company's starting balances from a CSV file, then applies one day's transfers from a second CSV file, in file order. A transfer is applied only if it is valid and leaves the paying account at $0.00 or more; otherwise it is rejected with a reason, and the run carries on. At the end, the program prints a report, writes the final balances to a new CSV file, and exits with status 0. Problems that make the day unsafe to process, such as an invalid balances file, stop the run with a clear error and exit status 1.

---

## Requirements (what the system must do)

### [1. Request summary](01-request-summary.md)
What the challenge asks for: load the balances of a single company, accept a day's transfers in a CSV file, and never let a balance go below $0. It also names the rubric the solution is judged on.

### [2. Functional requirements](02-functional-requirements.md)
FR-01 to FR-09: loading the balances, reading the transfers, applying a transfer, the $0 rule, unknown accounts, validation, transfer order, the end-of-day result and the runner. Each has Given / When / Then acceptance criteria with exact input and exact output, including the sample files' exact closing balances ([DEC-35](../design-analysis/design-decisions.md#dec-35)).

### [3. Non-functional requirements](03-non-functional-requirements.md)
NFR-01 to NFR-06: money exact to the cent, the cost of each operation, scale, language version and portability, readable code as the rubric describes it, and testability and coverage. Each is a measurable target with the way it is checked.

### [4. Scope](04-scope.md)
What is in scope, and everything the decisions leave out, such as several companies, storage between runs and retrying rejected transfers, each with its reason.

## Design (how it is built)

### [5. High-level design](05-high-level-design.md)
Four small diagrams of the whole program: where the CSV files are read, the domain models in the middle, where errors go, and where the report and output file go. It also shows where a new input format or a new transfer rule would be added.

### [6. Components](06-components.md)
Each component's job, its inputs and outputs, and what it does not do. `Account` is the aggregate root: the one model that owns a balance and guards the no-overdraft rule. Value checks live in the domain; checks on the shape of a file row live in the file-reading layer ([DEC-30](../design-analysis/design-decisions.md#dec-30)).

### [7. Logical flow](07-logical-flow/README.md)
A flowchart of applying one transfer, showing that every check runs before any balance changes ([DEC-18](../design-analysis/design-decisions.md#dec-18)). Sequence diagrams, one per page, for the sample run, a successful transfer, the $0 cases, an unknown account, an unreadable row, a missing file, and the run's output and exit code.

### [8. Alternatives](08-alternatives/README.md)
The options the decisions rejected, grouped by topic: money, accounts and the aggregate root, errors and rejected transfers, reading files, output and the runner, and logging. Each gives its pros, cons and cost, and why it was not chosen.

### [9. Considerations](09-considerations.md)
Error handling by layer, standard output, standard error and exit codes, the testing strategy, time and space costs, money and rounding, scale, portability and CI, extensibility, and known risks and limits.

### [10. Traceability, glossary and assumptions](10-traceability-glossary-assumptions.md)
A table linking every requirement to its decisions, the components that implement it and the test that proves it. It also defines every term and component name, lists the assumptions, and lists the small details decided while writing this design.

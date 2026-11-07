# 8. Alternatives

The main options the design decisions considered and rejected, grouped by topic, with why each was not chosen. Smaller rejected options are listed with their decisions in [`design-decisions.md`](../../design-analysis/design-decisions.md).

Every alternative here comes from a **Rejected** entry in [`design-decisions.md`](../../design-analysis/design-decisions.md). None of them is a new proposal. Each page gives, per alternative, a short description, its pros and cons, its time and space cost where that matters, and the reason it was not chosen, citing the decision.

Costs use "big O" notation: O(1) means the work stays the same however much data there is; O(n) means it grows in step with the number of rows or accounts, n.

| Page | Topic | Main decisions |
|---|---|---|
| [01 Money](01-money.md) | How amounts are held: floating point, rounding, truncating, accepting any format Ruby can parse, a money gem | [DEC-01](../../design-analysis/design-decisions.md#dec-01), [DEC-09](../../design-analysis/design-decisions.md#dec-09) |
| [02 Accounts and the aggregate root](02-accounts-and-aggregate-root.md) | Holding accounts without a repository; full domain-driven design; account numbers as integers | [DEC-08](../../design-analysis/design-decisions.md#dec-08), [DEC-30](../../design-analysis/design-decisions.md#dec-30), [DEC-31](../../design-analysis/design-decisions.md#dec-31) |
| [03 Errors and rejected transfers](03-errors-and-rejected-transfers.md) | Stopping on a bad transfer, retrying, creating unknown accounts, duplicate detection, loading only valid balance rows | [DEC-12](../../design-analysis/design-decisions.md#dec-12), [DEC-14](../../design-analysis/design-decisions.md#dec-14) to [DEC-17](../../design-analysis/design-decisions.md#dec-17) |
| [04 Reading files](04-reading-files.md) | Header detection, a hand-written parser, line-by-line parsing, streaming or chunking | [DEC-04](../../design-analysis/design-decisions.md#dec-04), [DEC-06](../../design-analysis/design-decisions.md#dec-06), [DEC-32](../../design-analysis/design-decisions.md#dec-32) |
| [05 Output and the runner](05-output-and-runner.md) | Overwriting, a date-only name, `--force`, named options, report contents | [DEC-22](../../design-analysis/design-decisions.md#dec-22), [DEC-25](../../design-analysis/design-decisions.md#dec-25) to [DEC-27](../../design-analysis/design-decisions.md#dec-27) |
| [06 Logging](06-logging.md) | A log file or service, info by default, `--verbose`, every level name, logging the full error, masking with a hash | [DEC-28](../../design-analysis/design-decisions.md#dec-28), [DEC-29](../../design-analysis/design-decisions.md#dec-29) |

**The common thread.** Most rejected options add code, settings or dependencies that the challenge does not ask for, or they change or hide what the company's files say. The chosen design keeps each rule in one place and makes every result exact and repeatable.

[Back to the solution design](../README.md)

# 8.1 Alternatives: money

How else amounts and balances could have been held and parsed, and why the `Money` model on `BigDecimal` was chosen instead.

The chosen design: `Money` holds an exact decimal (`BigDecimal`), accepts at most 2 decimal places, rejects anything else, and always writes exactly 2 ([DEC-09](../../design-analysis/design-decisions.md#dec-09)). How it is used is in [Components](../06-components.md) and [Considerations](../09-considerations.md).

## Floating point

**Description.** Hold amounts as Ruby `Float`, the computer's built-in binary number type for fractions.

**Pros**
- No extra library or model; arithmetic is built in.
- Slightly faster arithmetic, though the difference does not matter at this scale.

**Cons**
- Binary floating point cannot hold most decimal cents exactly. `25.60` is stored as a value very close to, but not equal to, 25.60.
- Small errors build up over many transfers. For example `0.1 + 0.2` gives `0.30000000000000004`.
- A balance that is off by a fraction of a cent can make the $0 check wrong: a transfer that leaves exactly $0.00 ([DEC-13](../../design-analysis/design-decisions.md#dec-13)) could be rejected, or the total check ([DEC-24](../../design-analysis/design-decisions.md#dec-24)) could fail.

**Cost.** O(1) time and space per amount, the same growth as `BigDecimal`.

**Why not chosen.** The rubric checks that the program "calculates test files accurately", and a balance off by one cent fails that ([DEC-09](../../design-analysis/design-decisions.md#dec-09)).

## Rounding (half-up or to even)

**Description.** Accept amounts with more than 2 decimal places and round them to the cent. Half-up rounds `10.005` to `10.01`; rounding to even ("banker's rounding") rounds it to `10.00`.

**Pros**
- Fewer rejected rows when a file has extra decimals.

**Cons**
- The program moves a different amount from the one the company wrote, with no sign that it did so.
- Two rounding rules give two different answers for the same file, so the choice itself becomes a business rule nobody asked for.

**Cost.** O(1) per amount; no difference from the chosen design.

**Why not chosen.** Rejecting instead of rounding never changes the amount the company asked for ([DEC-09](../../design-analysis/design-decisions.md#dec-09)).

## Truncating

**Description.** Cut off every digit after the second decimal place, so `10.009` becomes `10.00`.

**Pros**
- Simple, and never moves more money than written.

**Cons**
- Silently loses part of the amount, in one direction only.
- Hides a data error that the user needs to fix.

**Cost.** O(1) per amount; no difference from the chosen design.

**Why not chosen.** Same reason as rounding: the amount must be exactly what the file says, or the row is rejected ([DEC-09](../../design-analysis/design-decisions.md#dec-09)).

## Accepting any format Ruby can parse

**Description.** Let Ruby's own number parsing decide what is a valid amount.

**Pros**
- No format rule to write or test.

**Cons**
- Ruby accepts forms such as `1e3` (an exponent) and `+100`, which are not how money is written in a CSV file.
- What counts as valid would depend on the language, not on a stated rule.

**Why not chosen.** A strict format, digits with an optional point and 1 or 2 digits, makes every accepted value unambiguous ([DEC-09](../../design-analysis/design-decisions.md#dec-09)).

## A money gem

**Description.** Use a third-party library (a "gem") for amounts instead of the solution's own `Money` model.

**Pros**
- Less code to write; the library is widely used and tested.
- Brings features such as currencies and formatting.

**Cons**
- One more dependency to install, against the "standard library only" rule for runtime code ([DEC-01](../../design-analysis/design-decisions.md#dec-01)).
- Its own parsing and rounding rules would have to be checked against [DEC-09](../../design-analysis/design-decisions.md#dec-09), and may not match them.
- Currencies are not needed: money is in dollars and cents only (see the [assumptions](../../design-analysis/design-decisions.md#assumptions)).
- A small `Money` model of the solution's own shows the domain modelling the rubric looks for.

**Cost.** O(1) per amount, the same as the chosen design.

**Why not chosen.** The `Money` model on `BigDecimal` is enough, and avoids another dependency ([DEC-01](../../design-analysis/design-decisions.md#dec-01)).

[Back to the overview](README.md)
[Back to the solution design](../README.md)

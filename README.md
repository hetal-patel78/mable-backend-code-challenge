# Mable Back End Code Challenge

A solution to the Mable back-end take-home challenge: load the starting account balances for one company from a CSV file, then apply one day's transfers from a second CSV file, never letting an account balance go below $0.

The challenge as received is in [`docs/challenge/`](docs/challenge/MABLE_BACK_END_CODE_TEST.md).

## Status

Design analysis. The findings from reviewing the developer's analysis, and the follow-up clarifications, have been answered and consolidated into [`docs/design-analysis/design-decisions.md`](docs/design-analysis/design-decisions.md), which defines all behaviour and design. There is no implementation yet.

The findings are in the Google Sheet [Mable challenge: design analysis findings](https://docs.google.com/spreadsheets/d/1XVG6noS4dteY7kQlzVXHi5_njcN6MwQjDlsQpP9FKG4/edit?usp=drivesdk), one tab per type: definite gaps (D), judgement calls (J), possible extras (X), clarifications (C), big findings (B) and small findings (S), each with the developer's answer. A copy of each tab is in [`docs/design-analysis/clarifications/`](docs/design-analysis/clarifications/).

## Build

To be added once the implementation exists.

## Test

To be added once the implementation exists.

## Run

To be added once the implementation exists.

## Assumptions

To be listed with the implementation. Until then, every assumption is recorded as a decision in [`docs/design-analysis/design-decisions.md`](docs/design-analysis/design-decisions.md).

## Repository layout

| Path | Contents |
|---|---|
| `docs/challenge/` | The challenge brief and its two sample CSV files, unchanged |
| `docs/design-analysis/handwritten/` | The developer's handwritten brainstorm pages and high-level design sketch, unchanged |
| `docs/design-analysis/design-decisions.md` | The design decisions (`DEC-nn`): the single source of truth for behaviour and design |
| `docs/design-analysis/clarifications/` | The review findings and the developer's answers, exported from the Google Sheet as HTML (one page per tab), unchanged |
| `docs/prompts/` | The prompts given to the AI assistant, one log per phase |
| `CLAUDE.md` | Project instructions for the AI assistant |

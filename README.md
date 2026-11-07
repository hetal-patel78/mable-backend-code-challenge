# Mable Back End Code Challenge

A solution to the Mable back-end take-home challenge: load the starting account balances for one company from a CSV file, then apply one day's transfers from a second CSV file, never letting an account balance go below $0.

The challenge as received is in [`docs/challenge/`](docs/challenge/MABLE_BACK_END_CODE_TEST.md).

## Status

Design analysis. The findings from reviewing the developer's analysis, and the follow-up clarifications, have been answered. The answers are next consolidated into `docs/design-analysis/design-decisions.md`. No behaviour is decided yet and there is no implementation.

The findings are in the Google Sheet [Mable challenge: design analysis findings](https://docs.google.com/spreadsheets/d/1XVG6noS4dteY7kQlzVXHi5_njcN6MwQjDlsQpP9FKG4/edit?usp=drivesdk), one tab per type: definite gaps (D), judgement calls (J), possible extras (X) and clarifications (C), each with the developer's answer. A copy of each tab is in [`docs/design-analysis/clarifications/`](docs/design-analysis/clarifications/).

## Build

To be added once the implementation exists.

## Test

To be added once the implementation exists.

## Run

To be added once the implementation exists.

## Assumptions

To be listed once the design analysis has produced `docs/design-analysis/design-decisions.md`.

## Repository layout

| Path | Contents |
|---|---|
| `docs/challenge/` | The challenge brief and its two sample CSV files, unchanged |
| `docs/design-analysis/handwritten/` | The developer's handwritten brainstorm pages and high-level design sketch, unchanged |
| `docs/design-analysis/clarifications/` | The review findings and the developer's answers, exported from the Google Sheet as HTML (one page per tab), unchanged |
| `docs/prompts/` | The prompts given to the AI assistant, one log per phase |
| `CLAUDE.md` | Project instructions for the AI assistant |

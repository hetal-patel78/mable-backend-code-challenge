# Prompts: initial analysis and setup phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the initial analysis and setup phase, where the developer gave an instruction or made a decision. It records how the repository, its project instructions and the analysis inputs were set up, before the design analysis started. The design phase prompts continue in `prompts-design-phase.md`, numbered after the last prompt here.

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included. Where one led to a change, it is described in the line above the prompt that gave the instruction.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. Setting up the project instructions

<a id="p1"></a>**P1. Set out the project instructions and the prompt log** (described, not quoted)

The developer gave the instructions for `CLAUDE.md`:
- `docs/design-analysis/design-decisions.md` is the single source of truth, with a stable `DEC-nn` ID for every decision. Conflicts or uncovered cases are asked, never invented.
- Design decisions belong to the developer. The assistant may make small decisions only when they are consistent with the developer's answers, recording each with its reason and the rejected options, marked as the assistant's pick.
- The challenge files are never edited. Brainstorm pages and the developer's answers to review findings are kept unchanged as inputs.
- The work follows four steps, each written from the one before: design analysis, solution design document, GitHub Spec Kit specification, then test-first implementation through the Spec Kit tasks. Only the design analysis may start next, and only when the developer says so.
- The challenge's rubric is kept in view at every step.
- A decision is changed only after the developer confirms it, and is recorded only in `design-decisions.md`, with no history notes.
- The prompts that shape the design and code are logged, one file per phase in `docs/prompts/`, quoted exactly as typed, with numbering running across all the logs.
- Build only what the decisions describe. Commit locally only when asked, never push without approval, and squash into a few meaningful, incremental commits before a push, after the developer approves the plan.
- A root `README.md` gives build, test and run instructions and lists the assumptions.

Attached: `MABLE_BACK_END_CODE_TEST.md`.

Outcome: `CLAUDE.md` created at the project root with no design decisions in it. This prompt log was started in `docs/prompts/`. A root `README.md` was created with the build, test, run and assumptions sections left to fill in once the design and implementation exist.

# Prompts: implementation phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the implementation phase, where the developer gave an instruction or made a decision. It covers Part 2 of the [Spec Kit brief](../spec-kit/spec-kit-brief.md#part-2-implementation): the code and tests written through the Spec Kit tasks. Numbering continues from [`prompts-spec-creation-phase.md`](prompts-spec-creation-phase.md).

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. Part 2: Implementation

<a id="p26"></a>**P26. Run Part 2 of the Spec Kit brief** (described, not quoted)

After Part 1 was ready for review and its independent review findings were fixed, the developer instructed that the implementation start once the specs had been checked, without waiting for the developer to approve the specs. Part 2 of the brief runs from start to end as a multi-agent workflow (the Workflow tool), with the shared rules and the models in rule 6, from the pushed specs branch, and with the pushes the brief describes. As in Part 1 ([P25](prompts-spec-creation-phase.md#p25)), every review is done by an independent Claude Opus 5.5 agent that did not write or fix what it reviews.

Outcome: see the [run report](../spec-kit/implementation-run-report.md#part-2-implementation).

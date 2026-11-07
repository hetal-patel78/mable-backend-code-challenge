# Prompts: design phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the design phase, where the developer gave an instruction or made a decision. It covers the design analysis (reviewing the developer's analysis, agreeing answers and consolidating them into `design-decisions.md`) and the solution design. Numbering continues from [`prompts-initial-analysis-and-setup-phase.md`](prompts-initial-analysis-and-setup-phase.md).

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included. Where one led to a change, it is described in the line above the prompt that gave the instruction.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. Design analysis

<a id="p2"></a>**P2. Review the handwritten analysis against the challenge**

The prompt was given as an attached text file, with the message "read attached prompt and start the design phase". The file's text:

> Review my analysis in docs/design-analysis/handwritten/ (InitalBrainStorming-Page1 to Page4 and InitalBrainStorming-HLD) against the challenge in docs/challenge/ (MABLE_BACK_END_CODE_TEST.md, its rubric and the two sample CSV files) and report your findings only:
> - anything missing (requirements, edge cases, NFRs, design parts)
> - anything incorrect or not matching the challenge or its rubric
> - anything inconsistent between my pages
> - anything unclear or ambiguous in the challenge itself, where the challenge leaves behaviour undefined
>
> For each finding give: where it is (my page, or the challenge section or CSV file), what the issue is, why it matters, and severity (high / medium / low).
>
> Group the findings into three types, and give each finding an ID (D1, D2... / J1, J2... / X1, X2...):
> 1. Definite gaps or errors (D): things that clearly don't match the challenge.
> 2. Judgement calls (J): things the challenge leaves open, where more than one answer is reasonable. For these, list the options and their trade-offs, but do not pick one. I will decide.
> 3. Possible extras (X): things you considered that are NOT required by the challenge. List them so I can decide whether they are worth including or are over-engineering.
>
> For each finding, also state any assumption you made, so I can check it.
>
> Give me the findings as three tables and create a Google Sheet with the findings, one tab per type (D, J, X), each with an empty "My answer" column, and share it so anyone with the link can view it. Give me the link.
>
> Do not suggest fixes, do not write code and do not create or change any documents. I will answer the judgement calls one by one, and then ask you to review or challenge my decisions.

Outcome: 15 definite gaps (D1 to D15), 12 judgement calls (J1 to J12) and 13 possible extras (X1 to X13), given as three tables and in the Google Sheet [Mable challenge: design analysis findings](https://docs.google.com/spreadsheets/d/1XVG6noS4dteY7kQlzVXHi5_njcN6MwQjDlsQpP9FKG4/edit?usp=drivesdk), one tab per type with an empty "My answer" column, viewable by anyone with the link. No repository files were changed.

<a id="p3"></a>**P3. Review the answers and raise follow-up questions**

The developer answered every finding in the "My answer" column of the Google Sheet, then gave this prompt:

> I have provided all the answers on the sheet. Please go through it and let me know if you still need a clarification; add any follow-up questions as C1, C2... on a new Clarifications tab. Once you are happy with it I will download the image for each tab and we will store them in docs/design-analysis/clarifications/.

Outcome: 8 follow-up questions (C1 to C8) were added on a new "C Clarifications" tab of the same sheet: header rows, how an invalid balances file is reported, empty and all-rejected transfer files, command-line arguments, the default log level, the screen report, the Ruby version and the submission format. The developer answered all of them. Where an answer changed an earlier one (C1 replaces J5 on header rows), the later answer wins. No further questions were needed. The four tabs were exported from the sheet as HTML, one page per tab, and stored unchanged in `docs/design-analysis/clarifications/`.

<a id="p4"></a>**P4. A transfers file where every row is rejected**

The C3 answer covered only the empty transfers file. The assistant read the C6 answer as making an all-rejected file a completed run, and asked the developer to confirm. The developer's reply:

> Yes, that’s right: a transfers file where every row is bad is a completed run, exit status 0, with the output CSV written (balances unchanged) and every row listed as rejected with its reason. Also add a warning line to the report and the log: ‘All transfers were rejected; check this is the right file.’ A transfers file containing only a header row falls under this case too, since a header is a rejected row.

Outcome: at the developer's request, the answer was added to the C3 "My answer" cell in the Google Sheet, after the developer's existing text, and will be included in `design-decisions.md`. The warning is logged at warn level, so it shows with the default log level from C5.

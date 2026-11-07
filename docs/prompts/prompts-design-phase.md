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

<a id="p5"></a>**P5. Consolidate the answers into the design decisions**

The assistant had proposed writing `design-decisions.md` from the answers, followed by an independent review by a separate agent that had not seen the conversation. The developer's reply:

> start

Outcome: `docs/design-analysis/design-decisions.md` was written with 38 decisions (DEC-01 to DEC-38), each citing the findings and clarifications it comes from, an out-of-scope list, and 14 assistant's picks listed for the developer's review. A separate agent with no access to the conversation then reviewed it against the challenge and the developer's answers, and found 13 issues: none high, 4 medium, 9 low. It confirmed the expected sample results. The assistant fixed the wording, references and test coverage issues. Four questions that need the developer were added to the sheet as C9 to C12. The developer answered them, and the answers were added to the decisions.

<a id="p6"></a>**P6. Dated output files and the masking format**

The developer reviewed the assistant's picks in `design-decisions.md`:

> for Dec 25/27 - we should not overwrite existing file. Each day transfer create a new CSV final_balances_YYYY-MM-DD.csv and missing folders on the output path are created
>
> Add to DEC-25: if today’s output file already exists, the run stops with exit status 1.
>
> Dec 29 Keep DEC-29 as it is. Use ************6789 everywhere masked numbers appear, including the solution design, README and tests.

Outcome: DEC-27 now creates a new dated file for each day's run and never overwrites an existing file; creating missing folders on the output path became the developer's decision. DEC-25 stops the run with exit status 1 when today's output file already exists. The masking format in DEC-29 became the developer's decision, to be used everywhere masked numbers appear. DEC-03, DEC-22, DEC-26 and DEC-34 were updated to match, and new assistant's picks were added for the date used in the file name, the meaning of the third argument and when the existing file is checked.

<a id="p7"></a>**P7. The third argument is a full file path**

The assistant asked whether a third argument is a full file path used as given, or a folder for the dated file. The developer's reply:

> Yes, full path

Outcome: DEC-27 records that a third argument is the full path of the output file, used as given with no date added, and that the no-overwrite and create-folders rules apply to it. It became the developer's decision.

<a id="p8"></a>**P8. The developer's answers in the review sheet** (described, not quoted)

The developer answered every finding in the "My answer" column of the Google Sheet [Mable challenge: design analysis findings](https://docs.google.com/spreadsheets/d/1XVG6noS4dteY7kQlzVXHi5_njcN6MwQjDlsQpP9FKG4/edit?usp=drivesdk): 15 definite gaps (D1 to D15), 12 judgement calls (J1 to J12), 13 possible extras (X1 to X13) and 12 clarifications (C1 to C12). The answers are kept unchanged as one export per tab in [`docs/design-analysis/clarifications/`](../design-analysis/clarifications/):

- [`D Definite gaps.html`](../design-analysis/clarifications/D%20Definite%20gaps.html)
- [`J Judgement calls.html`](../design-analysis/clarifications/J%20Judgement%20calls.html)
- [`X Possible extras.html`](../design-analysis/clarifications/X%20Possible%20extras.html)
- [`C Clarifications.html`](../design-analysis/clarifications/C%20Clarifications.html)

Outcome: the answers are the input to `design-decisions.md`. Where a later answer differs from an earlier one, the later one wins.

<a id="p9"></a>**P9. Challenge the answers once more, then finalise the decisions**

The prompt was given as an attached text file, with the message "I know u have already created the designdecion.md but have look at the attached prompt and act accodingly". The file's text:

> I have answered everything in the sheet, including the clarifications. The PDFs, one per tab, are saved in docs/design-analysis/clarifications/.
>
> Please do these steps in order:
>
> 1. Update CLAUDE.md: under "Current stage", change the stage to the design analysis, and add the language and version I chose in the sheet. Show me the changed lines.
>
> 2. Log the sheet in docs/prompts/prompts-design-phase.md as the next prompt, pointing to the saved PDFs.
>
> 3. Review and challenge my answers once more, against the challenge, its rubric and each other. Also look for anything I have missed, small or big: edge cases, error cases, requirements, non-functional requirements, tests, documentation, or anything a reviewer could ask about. List everything you find in two groups:
>    - Small (edge cases, validation details, wording, test cases): decide these yourself, as in step 4, and show me what you decided.
>    - Big (anything that changes the design, conflicts with my answers, or adds scope): give me the options and their trade-offs, and wait for me to decide.
>    Give them to me as two tables I can paste into new tabs of the sheet (B for big, S for small), each with an empty "My answer" column. Then stop and wait for me.
>
> 4. For any other edge case or finding you come across from now on, document it and make the best decision yourself, so we don't stop for small things:
>    - record each one with its reason and the options you didn't pick, and mark it as "assistant's pick" so it is clear who decided
>    - keep it consistent with my answers in the sheet; if something conflicts with them, ask me instead of deciding
>    - only decide small things (edge cases, validation details, wording, test cases); anything that changes the design (classes, data structures, public methods, scope, new extras) still comes to me
>    - at the end, give me a short list of everything you decided, so I can review it
>
> 5. After I confirm step 3, write docs/design-analysis/design-decisions.md as the single source of truth:
>    - one decision per topic (for example loading the balances, applying a transfer, an account going below $0, money and rounding, validation and error handling, output and exit codes, the runner), grouped under headings
>    - each decision has a stable ID (DEC-01, DEC-02 and so on), the rule, the reason, the rejected options, and the finding IDs it comes from (for example "From: D1, J4, C3")
>    - write each decision as the current decision, with no "revised from" notes
>    - an "Assumptions" section and an "Out of scope" section, with a reason for each item
>    - a "To review" table listing every assistant's pick, and an "Agreed by the developer" table
>    - no separate review-trail file is needed, as the sheet PDFs keep the full history
>    - simple, plain English
>
> Do not start the solution design or write any code yet.

Outcome: steps 1 to 3 done. `CLAUDE.md` names the stage and the language and version (Ruby, latest 3.4.x, with RSpec). The sheet is logged as P8; the tabs were saved as HTML exports, not PDFs, so P8 points to those. The review gave big findings (B) for the developer to decide and small findings (S) decided by the assistant, as two tables for new tabs of the sheet. Step 5 waits for the developer's answers.

<a id="p10"></a>**P10. Answers to the big and small findings**

The findings from P9 were added to the sheet as two new tabs, "B Big" (B1 to B4) and "S Small" (S1 to S12). The developer answered them there, then wrote:

> ok have added my answers to B Big and S Small as well

The answers: B1 (c), the time is added to the default output name; B2 (a), each rule is tested once in unit specs, with fixture files only for file-level behaviour and four end-to-end runs; B3 (a), a header stays a bad row, with a clear message and a README note; B4 (a), the class that runs the day takes the run date as a constructor argument. All of S1 to S12 were agreed.

The two tabs are saved unchanged in [`docs/design-analysis/clarifications/`](../design-analysis/clarifications/) as [`B Big.html`](../design-analysis/clarifications/B%20Big.html) and [`S Small.html`](../design-analysis/clarifications/S%20Small.html).

Outcome: step 5 of P9 done. `design-decisions.md` was rewritten in the format P9 asks for: 38 decisions with the same IDs, each giving the rule, the reason, the rejected options and the findings it comes from, plus Assumptions and Out of scope sections with reasons, a "To review" table of 18 assistant's picks and an "Agreed by the developer" table. Because the default file name now includes the time (B1), the constructor argument from B4 is the run time rather than only the date; this is listed as an assistant's pick.

<a id="p11"></a>**P11. When the header message is shown**

The developer reviewed the assistant's pick in DEC-06:

> DEC-06: agree, with one change: show the header message when the first data row’s first field contains no digits at all (for example account or from), instead of ‘contains a letter’, so a mistyped account number like 1111O34522226789 isn’t described as a header

Outcome: DEC-06 shows the header message when the first data row's first field contains no digits at all. The rule became the developer's decision and moved from "To review" to "Agreed by the developer".

<a id="p12"></a>**P12. The remaining assistant's picks**

The developer reviewed the remaining 17 assistant's picks in `design-decisions.md`:

> all the rest looks good

Outcome: all 17 picks moved from "To review" to "Agreed by the developer", which now gives each agreed pick its reason, the options rejected and where it was agreed. "To review" is empty.

<a id="p13"></a>**P13. Independent review of the design decisions**

> Ask a separate agent (Opus 5.5) to review docs/design-analysis/design-decisions.md against the challenge, its rubric and my answers in docs/design-analysis/clarifications/. It may fix wording, complexity, finding IDs and missing small picks (add those to the "To review" table). Anything that would change a decision comes back to me as a list with options, not as an edit.

Outcome: a separate agent (Opus 5.5) with no access to the conversation reviewed the file. It confirmed the expected sample results and found no decision contradicting the challenge, the rubric or the developer's answers. It edited only what the prompt allowed: two missing **[assistant's pick]** markers, one wording fix, missing finding IDs in four "From:" lines, and four new small picks added to "To review". It returned three low-severity questions (R1 to R3) for the developer, with options. The assistant checked every edit against a copy of the file taken before the review.

<a id="p14"></a>**P14. Answers to the review questions**

> R1: (a) Test the error path with a fake repository whose total changes, and check the error message, no output file, no report and exit 1.
>
> R2: (a) Show the header hint only when the first field is not empty and contains no digits.
>
> R3: Show the output path relative to the folder the command was run from, or the full path if it’s outside that folder.

Outcome: DEC-24 and DEC-34 test the failed total check with a fake repository whose total changes. DEC-06 shows the header message only when the first field is not empty and contains no digits. DEC-26 shows the output path relative to the folder the command was run from, or in full when outside it; this replaces the assistant's pick on how the path is shown. R3 was the developer's own option, not one of those offered.

<a id="p15"></a>**P15. The picks added by the independent review**

The developer reviewed the 4 assistant's picks the review added to "To review":

> Agree all 4

Outcome: the 4 picks moved to "Agreed by the developer". "To review" is empty.

## 2. Solution design

<a id="p16"></a>**P16. Write the solution design**

The prompt was given as an attached text file, with the message "Now read the attached prompt and start the Solution  Design and run the parallel execution whenever possible so SD is created fast". The file's opening lines:

> I have finished my design decisions. I agree with the assistant's picks in the "To review" table of design-decisions.md; please move them to "Agreed by the developer".
>
> Now I want you to turn the decisions into a solution design document. First, save this brief as docs/solution-design/solution-design-brief.md, then follow it exactly, including its stops for my review.

The rest of the file is the brief itself, saved unchanged as [`docs/solution-design/solution-design-brief.md`](../solution-design/solution-design-brief.md).

Outcome: the brief was saved. The "To review" table was already empty, so no picks needed moving. Step 1 of the brief was done: the sources were read, and the proposed outline, names, open questions and small decisions were given to the developer for approval.

<a id="p17"></a>**P17. Approve the outline**

> Approve

Outcome: the outline of `docs/solution-design/` and the proposed names (`AccountRepository`, `TransferService`, `UnknownAccount`, `DuplicateAccount`, `InsufficientFunds`, `LoadBalances`, `ProcessDailyTransfer`, `DayResult`, `BalancesCsvReader`, `TransfersCsvReader`, `FinalBalancesCsvWriter`, `ReportPrinter`, `Runner`) were approved. Step 2 of the brief was done: the parent page `docs/solution-design/README.md` was written, and work stopped for the developer's review.

<a id="p18"></a>**P18. Approve the parent page, and how pages are committed and measured** (described, not quoted)

The developer approved the parent page ("Looks good"), then answered two open questions:

- Q1, how each page is committed and pushed: "Commit and push each page", as the brief says.
- Q2, how cost and scale are stated: "no timing test for this one also update the main prompt accordingly."

Outcome: cost and scale are stated as growth rates, checked by design review, with no timing test. At the developer's request, the brief in `docs/solution-design/solution-design-brief.md` was updated to say so. Step 3 of the brief started.

# Solution design brief

The developer's instructions for writing the solution design document. Follow them exactly.

SOURCES (use only these; do not invent requirements):
1. Source of truth for every rule and design decision: docs/design-analysis/design-decisions.md
2. The original challenge and its rubric: docs/challenge/MABLE_BACK_END_CODE_TEST.md, with the sample files mable_account_balances.csv and mable_transactions.csv
3. Background only (read it, but do not take rules from it): the handwritten analysis in docs/design-analysis/handwritten/, the review answers in docs/design-analysis/clarifications/, and CLAUDE.md.

Precedence: design-decisions.md wins. Where anything else differs from it, follow design-decisions.md; this is not an open question.
List an open question only if design-decisions.md does not cover something, contradicts itself, or contradicts the challenge. Small gaps you may decide yourself under the CLAUDE.md rule (mark them as the assistant's pick and list them). Anything bigger, ask me.
Do not change design-decisions.md. The solution design adds detail (how); it must not change or contradict any decision (what).

NAMES: Use the names in design-decisions.md exactly. For the parts it describes but doesn't name, propose names in the outline for my approval.

WHERE: Markdown files in docs/solution-design/

STRUCTURE (parent and child pages):
- One parent page (README.md) a reviewer can read in 5 minutes to understand the whole design. For each section: a 2-4 line summary and a link to the child page.
- One child page per section. Each starts with a one-line purpose and ends with a link back to the parent. Pages 7 and 8 are overviews with their own child pages, in 07-logical-flow/ (one page per flow) and 08-alternatives/ (one page per category).
- Relative links, so they work on GitHub.
- Wherever a requirement, component or design point comes from a decision, cite its DEC ID and link to design-decisions.md.
- Keep it in proportion to this challenge: short pages, no repetition between pages.

SECTIONS:
1. Request summary: what the challenge asked for, in a few sentences.
2. Functional requirements: FR-01, FR-02, ... for loading the balances file, reading the transfers file, applying a transfer, a transfer that would take an account below $0, a transfer naming an account that is not loaded, validation of account numbers and amounts, the order transfers are applied in, the end-of-day result and its output, and the runner. Each cites its DEC IDs and has acceptance criteria in Given / When / Then form with exact input and exact expected output (standard output and standard error shown separately). Include the challenge's sample files as an acceptance criterion, with the exact closing balance of every account.
3. Non-functional requirements: NFR-01, ... for money accuracy, the cost of each operation, scale (file size and number of accounts), language version and portability, code organisation and readability (as the rubric describes it), and testability and coverage. Each cites its DEC IDs and says how it will be checked. State each NFR as a measurable target (for example "every balance is exact to the cent after any number of transfers"), without naming data structures or classes. The how belongs in pages 5-10. State the cost of each operation and the scale as growth rates (for example "applying one transfer takes the same time however many accounts there are"), checked by design review; there is no timing test.
4. Scope: in scope, and the out-of-scope list from design-decisions.md, with a reason for each item.
5. High-level design: a Mermaid architecture diagram and a short explanation. It must show where the CSV files are read, the domain models, where errors go and where the output goes, and answer at a glance how another input format or another transfer rule would be added, as far as the decisions cover it.
6. Components: one section per component. For each: its responsibility, what goes in, what comes out, and what it does NOT do. Show which class owns which data, which class is the aggregate root and why, and which checks belong to the domain and which to the file-reading layer.
7. Logical flow and sequence diagrams: a Mermaid flowchart of applying one transfer, showing the validation order and that every check runs before any balance changes. Mermaid sequence diagrams for: the sample files end to end; a successful transfer; a transfer rejected because it would take the account below $0, with both balances unchanged; a transfer that leaves an account at exactly $0; a transfer naming an unknown account; a row that cannot be read; a missing file; the full run's output and exit code.
8. Alternative solutions, grouped into categories taken from the rejected options in design-decisions.md (for example how money is represented, how accounts are held and which model is the aggregate root, and how errors and rejected transfers are handled). For each: a short description, a small Mermaid diagram where it helps, pros, cons, its time and space cost where relevant, and why I did not choose it.
9. Considerations: error handling, domain versus file reading versus runner; standard output, standard error and exit codes; testing strategy with a Mermaid test-flow diagram (unit, integration, end-to-end against the sample files); the time and space table with its reasoning; money and rounding; scalability (very large files, many companies, what changes in production); portability and CI where decided; extensibility; risks and known limitations.
10. Traceability, glossary and assumptions: a table linking each FR and NFR to its DEC IDs, the component(s) that implement it, and the kind of test that proves it; every term and component name defined once; the assumptions from design-decisions.md and any open questions.

RULES:
- Simple, plain English that anyone can understand. Short sentences. Explain any technical term the first time it is used.
- Use the component names exactly as agreed.
- Use "must" for requirements. Avoid vague words like "should", "etc." or "appropriate".
- Keep requirements (WHAT) separate from design (HOW): pages 1-4 describe only what the system must do, with no class names. Pages 5-10 describe how.
- Keep each Mermaid diagram small and readable (about 8 boxes at most). Split big diagrams.
- No code, except very small snippets when they explain a design point.
- Every DEC ID must be cited at least once across the pages. The traceability page lists any DEC that is not cited, with the reason.

HOW TO WORK:
Step 1: Read all sources. Then show me only the proposed outline: the list of files and a one-line purpose for each, the proposed names for the unnamed parts, plus any open questions and any small decisions you made. Stop and wait for my approval.
Step 2: After I approve, write the parent page and stop for my review.
Step 3: Then write the remaining child pages as a workflow, in parallel where a page does not depend on another. For each page: create it, have a separate agent (Opus 5.5) review it, fix it, review it again, then commit and push that page on its own so each commit is small.

Do not start the Spec Kit specification or write any code yet.
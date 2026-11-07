# Prompts: spec creation phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the spec creation phase, where the developer gave an instruction or made a decision. It covers the GitHub Spec Kit specification: the brief, the constitution, the specs, plans and tasks. Numbering continues from [`prompts-design-phase.md`](prompts-design-phase.md).

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. Spec Kit brief

<a id="p20"></a>**P20. Set up Spec Kit and write the Spec Kit brief**

The prompt was given as an attached text file. The file's text:

> The solution design is finished. The next step is the GitHub Spec Kit specification (step 3 in CLAUDE.md). The implementation (step 4) comes later, with its own prompt.
>
> First check that Spec Kit is installed (.specify/ and the /speckit-* skills in .claude/skills/). If it isn't, install it (specify init --here --integration claude --script ps) and tell me the version. Also check that the repository has a GitHub remote, because the run pushes branches. If it doesn't, tell me.
>
> Then write docs/spec-kit/spec-kit-brief.md. It has shared rules, then Part 1 (specification). Leave a heading for Part 2 (implementation), which I will give you later. Part 1 runs in its own new session, on its own, without waiting for me. I review the specs after it.
>
> SHARED RULES
>
> 1. Sources: design-decisions.md (source of truth), then docs/solution-design/ (main input, start from its README), then CLAUDE.md. The handwritten analysis and clarifications are background only, and agents do not need to read them.
>
> 2. One constitution with lasting principles only, taken from the decisions and the rubric: domain models that encapsulate their own rules, separation of concerns (reading files, the domain, and the output are apart), short readable methods, tests first with orthogonal RSpec specs that explain the behaviour, check everything before any balance changes, money exact to the cent, no over-engineering, standard output for results only. Detailed rules stay in design-decisions.md and the constitution points to it.
>
> 3. Specs. Each FR and NFR is owned by exactly one spec. Propose the split from page 10 (traceability), along these lines:
>    - 001-domain: the domain models and their rules (accounts, money, transfers, and whatever design-decisions.md names), and the project skeleton (Gemfile, folder layout, RSpec setup), because the others build on it.
>    - 002-file-runner: reading the two CSV files, the runner, the output, the error messages and exit codes, and the end-to-end test on the challenge's sample files with the exact closing balance of every account.
>    - 003-delivery: the README with its assumptions and "How this was built", any test-data files, CI if the decisions include it, and a check of what the submission holds.
>    If two specs would be clearer for a project this size, say so and why. Show the table of what each spec owns and which pages it uses, and stop for my approval before writing the rest of the brief.
>
> 4. How the tests are split:
>    - 001 tests each of its FRs by calling the domain directly: the result, the error class and its exact message, and that no balance changes after every failure.
>    - 002 runs every FR's page 2 scenario through the runner with real CSV files, with exact standard output, standard error and exit code.
>    - The domain owns the exact message text of every error. The runner never rewrites a message; it only adds what page 9 says it adds (for example the row number).
>
> 5. Rules:
>    - No new behaviour, and nothing that is out of scope on page 4.
>    - Copy character for character anything a test compares: every message in page 9's table, the output format of every balance and line, and every exit code.
>    - Every acceptance scenario states standard output, standard error and the exit code separately, copied from page 2.
>    - Names and members exactly as on page 6 and in the page 10 glossary. Where page 10 leaves a name open, the plan picks it and lists it under "Decided in the run".
>    - Technical choices are already made in design-decisions.md: the Ruby version, RSpec, Bundler, and the project layout on page 5. Nothing else is added (no framework, no gems beyond those the decisions name, no logging library).
>    - Tests come first in every tasks file, and each phase ends with its specs passing. Every edge case listed in design-decisions.md has a planned test.
>    - Every requirement, scenario, task and test cites its FR or NFR and DEC IDs where it helps.
>    - Decide small gaps yourself, write them into the spec and list them in the run report. Change design-decisions.md or the solution design only if it blocks a full, working, error-free system, in its own commit starting "Run change:", following the chain. Never pass by weakening a test or changing an expected output to match the code. No [NEEDS CLARIFICATION] may be left in any spec.
>    - Never delete anything, and keep the git history.
>    - Worktrees go in C:\Dev\, never inside the repository.
>    - Commit in small steps, each with a clear message naming what it covers. Push each spec's branch with its small commits kept, never as one big commit.
>    - Push main only after a separate review agent that did not write or fix the changes approves. Never force push.
>
> 6. Models: opus for writing and reviewing the specs, for decisions and for the review before pushing main; sonnet for fixing spec findings; haiku for scripted checks and updating the report. A haiku or sonnet agent that fails the same task twice hands it to opus.
>
> 7. A run report in docs/spec-kit/implementation-run-report.md, with a section for Part 1, written early and updated after every step: status, check results, decided in the run, changed in the run, fixed in review, and what is left for me. The inputs to each /speckit-* command go in docs/spec-kit/specify-inputs.md. The starting prompt of Part 1 is logged in docs/prompts/prompts-spec-creation-phase.md, numbered after the last prompt in docs/prompts/.
>
> PART 1: SPECIFICATION (no code)
> - Write the constitution, then create the specs one after another so they are numbered in order, and commit.
> - Then for each spec in parallel, in its own worktree: clarify, plan and tasks; review it; fix every finding; review again with a fresh reviewer that did not write it. Repeat until a review finds 0 defects, with no limit on rounds. Then push that spec's branch.
> - Then cross-check the specs together (the same names, strings and outcomes everywhere, each FR and NFR owned once, no contradictions), fix and check again until nothing is found.
> - Run scripted checks on the whole specification: coverage of every FR and NFR, exact strings, channels and exit codes, names, every edge case in design-decisions.md has a planned test, analyze with no CRITICAL or HIGH issue, and no code under lib/, bin/ or spec/.
> - Merge into one specs branch, keeping the small commits, push it, then push main after the separate review.
> - Stop. The report says "Specification ready for review".
>
> When the brief is written, stop so I can review it. After I approve it, give me the short prompt that starts Part 1.

Outcome: Spec Kit 1.2.6.dev0 was installed with the Claude integration and the PowerShell scripts, and the GitHub remote was confirmed. The brief [`docs/spec-kit/spec-kit-brief.md`](../spec-kit/spec-kit-brief.md) was written with the shared rules, Part 1 and Part 2, and the developer approved it.

<a id="p21"></a>**P21. Keep three specs**

The assistant proposed three specs (`001-domain`, `002-file-runner`, `003-delivery`) and recommended against one spec per FR and NFR. The developer chose the three specs:

> then go back to our original plan keep 3 specs

Outcome: the brief lists three specs, `001-domain`, `002-file-runner` and `003-delivery`, with each FR and NFR owned by exactly one.

<a id="p22"></a>**P22. Keep the small commits on the spec branches**

The Spec Kit prompt ([P20](#p20)) says to push each spec's branch with its small commits kept, while `CLAUDE.md` says to squash small commits before a push. Asked which applies to Part 1, the developer answered:

> Keep small commits

Outcome: in Part 1, each spec's branch and the merged specs branch are pushed with their small commits kept, with no squash. The brief says so.

<a id="p23"></a>**P23. Approve "Run change:" commits in advance, and record the cross-page answers as decisions**

The assistant asked whether the Spec Kit prompt ([P20](#p20)) counts as approval in advance for a "Run change:" commit to `design-decisions.md` or the solution design, and whether the answers to the cross-page design questions ([P19](prompts-design-phase.md#p19)) should be added to `design-decisions.md`. The developer answered:

> Does your prompt count as approval in advance? - yes
> OQ1–OQ5 answers: should I add them to design-decisions.md - yes

Outcome: the P19 answers were added to [DEC-12](../design-analysis/design-decisions.md#dec-12), [DEC-23](../design-analysis/design-decisions.md#dec-23), [DEC-30](../design-analysis/design-decisions.md#dec-30) and [DEC-31](../design-analysis/design-decisions.md#dec-31). The name `include?` is listed for review. The brief says that a "Run change:" commit in Part 1 needs no further approval, only when the change is needed for a full, working, error-free system.

## 2. Part 1: Specification

<a id="p24"></a>**P24. Run Part 1 of the Spec Kit brief**

The prompt that started Part 1, given to a new session:

> Run Part 1 (Specification) of `docs/spec-kit/spec-kit-brief.md`, following its shared rules exactly. Use a workflow (multi-agent orchestration with the Workflow tool) for the parallel steps, with the models in rule 6. Start from the local branch `spec-kit-setup`, which is checked out in `C:\Dev\mable-backend-code-challenge` and holds the Spec Kit set-up, the brief and the latest decisions; it is not pushed yet. Worktrees go in `C:\Dev\`, never inside the repository. Log this prompt as the next number in `docs/prompts/prompts-spec-creation-phase.md` (rule 7). Stop when the run report says "Specification ready for review". Do not start Part 2.

Outcome: see the [run report](../spec-kit/implementation-run-report.md#part-1-specification).

<a id="p25"></a>**P25. Use independent Opus reviewers for every review** (described, not quoted)

During the Part 1 run, the developer instructed that every spec review in Part 1 is done by an independent Claude Opus 5.5 agent that did not write or fix what it reviews, so that any issues are picked up. This covers the per-spec review rounds, the cross-check and the review before `main` is pushed, and the reviewer model is recorded for each round in the run report.

Outcome: every review in Part 1 ran on Opus with a new agent each round, and the [run report](../spec-kit/implementation-run-report.md#part-1-specification) records the reviewer of each round.

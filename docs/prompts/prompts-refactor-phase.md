# Prompts: review and refactor phase

This file lists the prompts given to the AI assistant (Claude Code, model Claude Opus 5.5) during the review and refactor phase, where the developer gave an instruction or made a decision. It covers the developer's review of the solution after the implementation. Numbering continues from [`prompts-implementation-phase.md`](prompts-implementation-phase.md).

- Prompts are quoted **exactly as typed**, including typos. Where an instruction was given across a discussion rather than typed as one prompt, it is described instead of quoted.
- Prompts that only asked a question, or only asked for a commit, are not included.
- Files attached to a prompt are listed under it rather than quoted.

Back to [project instructions](../../CLAUDE.md).

---

## 1. README

<a id="p27"></a>**P27. Add prerequisites, troubleshooting and how the solution would evolve to the README**

> What I suggest adding a perquisite to the read me so reviewer know the issue if it happen and trouble shooting part as well on how to fix it
>
> I am also suggesting to add some details about
>
> […]
>
> This purely for you reference

Outcome: the [README](../../README.md) gained two sections: [Prerequisites](../../README.md#prerequisites) and [Troubleshooting](../../README.md#troubleshooting). [DEC-37](../design-analysis/design-decisions.md#dec-37) lists them. A section on how the solution would evolve was drafted, then left out ([P29](#p29)).

## 2. Screen report

<a id="p28"></a>**P28. Show each account's opening balance next to its closing balance**

> also  in  regards to in order to check I had to check the balance csv and I am wondering what are the efforts required to add fields Like From Account , Previous Balance, Remaining balance 
>
> This is purely for clarity?
>
> Just tell me the efforts don't start the implementation yet

Attached: the `Final balances` section of the sample report.

After the effort estimate, with the opening and closing balance per account recommended over balances on each transfer line:

> ok run it on separate agent

Outcome: the `Final balances` section of the screen report shows each account's opening and closing balance as a table ([DEC-26](../design-analysis/design-decisions.md#dec-26)). The output CSV is unchanged.

## 3. README, revised

<a id="p29"></a>**P29. Leave out how the solution would evolve**

> thinking on my ask ask I think we don't need to mentioned how it will evolve. I will keep it for my reference but don't need it to send to the reviewer

Outcome: the README has no section on how the solution would evolve.

# Working with your agent

Give the agent the outcome you want and any limits that matter. A task description,
GitHub issue, or existing tracker link is enough to start. You should not need to
learn the agent's internal process to get a useful pull request.

## When the agent asks questions

Questions can happen before work or during implementation. They should arrive
before the answer becomes expensive to change, rather than waiting for PR review.

| Situation | What the agent does |
| --- | --- |
| The goal or acceptable behavior is unclear | Reads the existing context, then asks the smallest question needed to proceed. |
| Several routine, reversible approaches fit the request | Chooses one and continues; mentions the assumption if it affects your expectations. |
| Implementation reveals a product tradeoff, wider scope, or consequential risk | Explains the discovery, recommends a path, and asks before dependent work continues. |
| An answer is pending | Continues useful independent work. Does not treat silence as approval. |
| The PR is ready | In **Ask**, requests one merge decision unless already authorized. In **Auto**, merges after the required checks and approvals pass. |

For example, a question discovered while fixing an import could be:

> Some rows contain invalid dates. I recommend accepting the valid rows and
> showing the others for correction, so useful work can proceed without invented
> dates. Is partial import acceptable, or must the whole file succeed together?

The question makes the consequence understandable. It does not ask you to choose
an internal parser, review a token log, or wait until the code is finished.
Related questions can come together; a mandatory questionnaire is unnecessary.
An answer remains part of the existing task or PR, subject to its privacy, so the
agent can use it later without asking again.

## A short message, with evidence available

One owner communicates with you even when bounded assistants help with the work.
Updates explain meaningful progress or a change in direction. The final message
answers: what happened, where is the PR, and is a decision still needed?
Keep a short validation result visible. Required decisions, important risks, and
limitations that change the conclusion must also stay visible.

The following is an illustrative PR summary, not a report of an actual change:

> The import now identifies invalid dates and accepts the remaining valid rows.
> Focused tests and required CI pass. Ready for your merge decision.
> Complete token usage is UNKNOWN because external reviewer usage is unavailable.

<details>
<summary>Example: verification and usage details</summary>

The PR would record the tested commit, actual commands and results, and links to
CI. Its code walkthrough would explain the change and important code choices.
Model and usage rows would identify the contributing commits, configured model
and effort, available native token counts, shared work, and missing contributors.
These are supporting records; opening this block is not an extra approval step.

</details>

Use descriptive labels such as “Verification” and “Model and token usage.” Keep
the walkthrough's main explanation outside the collapsed evidence. In a chat
that does not render collapsible blocks, link to the PR's details instead of
pasting its logs. A failure or changed risk should appear in the next update,
even if the supporting command output is collapsed.

Collapsed content remains readable and public wherever the PR is public. It is
not private storage. Keep prompts, raw sessions, private identifiers, and secrets
out of published evidence. Collapsing text also does not reduce its token cost
when an agent loads it. Keep useful evidence once and retrieve details as needed.

## Knowing whether communication improved

For real pilot changes, use the existing task and PR history to assess how much
reading, repeated explanation, decision-making, and corrective work the maintainer
needed. Include waiting caused by questions asked too late. Human active time
needs a human estimate; elapsed timestamps cannot establish it.

Check that the outcome is understandable without expanding evidence, that needed
questions arrived in time, and that available model/token records can still be
found. Compare similar accepted changes using the
[pilot's success criteria](pilot-plan.md#success-evidence-and-commit-attribution).
No new survey, communication score, or reporting gate is required.

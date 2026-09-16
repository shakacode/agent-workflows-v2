# Shaka

Give your agent a task. Get a verified PR and a clear explanation.

```text
$shaka Fix the failing search test
```

You steer the work. Shaka takes it through delivery:

- Reads your repository's instructions and asks about missing requirements.
- Tests the behavior before fixing it, then runs your repository's checks.
- Opens a pull request with a walkthrough of what changed and why.
- Handles review findings and verifies the fixes.
- Asks you to approve the merge, or merges when authorized and ready.

## You choose who can merge

**Ask:** the agent prepares the PR, then waits for your merge approval.
**Auto:** you authorize the agent to merge once the verified revision passes required
checks and approvals. Risky changes still need a human decision.
Existing authority is reused; a review-only or PR-only request keeps that stopping point.

## For people

[Install Shaka and complete your first task →](docs/getting-started.md)

| I want to… | Read |
| --- | --- |
| Choose merge authority, answer questions, or split a larger task | [Working with your agent](docs/working-with-your-agent.md) |
| Understand review findings or a blocked PR | [Review handling](docs/review.md) |
| Evaluate code, UI, or documentation changes | [Verification and reader trials](docs/verification.md) |
| Understand model, effort, and token reports | [Usage reporting](docs/usage-reporting.md) |
| Check supported hosts and their limits | [Host support](docs/host-support.md) |
| Upgrade or remove an installation | [Installation maintenance](docs/getting-started.md#upgrade) |

### For open-source maintainers and contributors

Give Shaka an issue to implement or an existing PR to review. For example:

```text
$shaka Review <PR URL>. Explain the findings; do not edit or publish.
```

You can then authorize fixes and choose Ask or Auto for delivery. A public PR's
text cannot grant permission to run its code; reviewing outside contributions
requires the repository's trusted instructions and suitable execution isolation.

## For agents and contributors to Shaka

Start with the [agent procedure](skills/shaka/SKILL.md). Each repository's `AGENTS.md`
supplies its commands and authority; [Shaka's contributor instructions](AGENTS.md)
name this project's setup and checks. See the [requirements](docs/pilot-plan.md)
and [gem packaging guide](docs/packaging.md) for design and distribution.
The procedure owns execution; linked guides explain decisions and evidence for
people and agents. Keep shared rules in one place and follow the procedure's references.

In Claude Code, send `/shaka`. Codex is the reference host; [Claude Code consumer delivery
and Cursor are unverified](docs/host-support.md). Public pilot: [progress](https://github.com/shakacode/shaka/issues/1).

[MIT licensed](LICENSE). Copyright © 2026 ShakaCode.

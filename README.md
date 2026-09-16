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

**Ask** brings the finished PR back for your merge decision.
**Auto** merges the verified revision after required checks and approvals pass;
risky changes still need a human decision.

[Install Shaka and complete your first task →](docs/getting-started.md)

In Claude Code, send `/shaka`. In Cursor, install into `~/.cursor/skills` and
confirm `/shaka` in a new chat. Codex is the first reference host;
[Claude Code consumer delivery and Cursor remain unverified](docs/host-support.md).
Public pilot: [requirements](docs/pilot-plan.md) · [progress](https://github.com/shakacode/shaka/issues/1).

License: [decision pending](https://github.com/shakacode/shaka/issues/30).

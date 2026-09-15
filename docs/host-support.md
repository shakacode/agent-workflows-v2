# Host support

Codex CLI is the reference host for this pilot and Claude Code the second host.
Follow the [getting-started guide](getting-started.md) for installation and your
first task. Neither Claude Code nor Cursor has a verified complete V2 consumer
delivery yet.

The hosts share one `shaka` skill and the same Ruby helpers for GitHub
operations. Your repository keeps its existing `AGENTS.md`, commands, and policy.
Host-specific work covers installation, instruction loading, execution permissions,
and reading native usage records. It does not create three copies of the workflow.

## What has been verified

These observations were made on September 14 and 15, 2026. A successful install or CLI
startup does not establish a complete workflow, and workflow success does not
establish complete usage attribution.

| Capability | Codex CLI 0.154.0 | Claude Code desktop 2.1.270, CLI 2.1.272 | Cursor CLI 2026.09.10-fd3934a |
| --- | --- | --- | --- |
| Installation and startup | Dedicated skill installation and explicit trusted-file startup checked. | A symlinked personal skill loaded in the desktop app and in `claude -p`; `/shaka` asked for the task and merge preference and stopped before edits. A same-named repository skill did not replace it. | Dedicated CLI package version/help checked; V2 instruction activation unverified. |
| OS write boundary | A native workspace sandbox denied writes to the separate trusted source, installed link, and link directory while allowing the session and target checkout. | No launcher or sandbox; the user's permission mode applies. Not separately probed. | Native V2 sandbox boundary unverified. |
| Real workflow | Protected PR operations exercised in V2. A fresh CLI task implemented and verified the Astro website guides through its repository seam; the owning task handled publication. | Consumer delivery unverified. | Consumer delivery unverified. |
| Usage | Reader matched 14 real CLI responses and repeated-source input without double counting; attribution remains partial. | Reader matched an independent per-response aggregate for a desktop session with a subagent and two models, and Claude Code's own totals for two CLI runs. | Complete V2 token and effort reporting unverified. |

The Codex write test establishes that particular local boundary. It does not
establish equivalent behavior in the desktop app, other versions, or other hosts.
Repeated consumer use, including failed checks, changed PR heads, and Ask/Auto
stopping behavior, is still required before claiming broader adoption.

## Codex first

Use the canonical [startup instructions](getting-started.md).
Keep the trusted workflow source and installed link outside both the writable
session directory and target checkout. The guided startup names the trusted skill for the agent; do not add a discovery
link inside the writable session.

The launcher or direct invocation must establish the intended permissions even
when the user's existing configuration grants broader access. Temporary writable
directories also count: placing the trusted skill in a system temporary directory
can undermine an otherwise separate installation. See the
[Codex permissions documentation](https://learn.chatgpt.com/docs/permissions)
for the host's controls; the getting-started guide owns the tested V2 recipe.

## Claude Code

Use the [Claude Code install recipe](getting-started.md#use-shaka-in-claude-code).
Claude Code runs a personal skill instead of a same-named skill in a repository's
`.claude/skills`, as its [skill locations](https://code.claude.com/docs/en/skills)
document; the September 15 trial confirmed this with a canary repository copy.
There is no `shaka work` launcher for Claude Code. Start `claude` in the repository,
keep the trusted source outside any `--add-dir` directory, and rely on the permission
mode you already use. The next required evidence is a complete ordinary consumer PR
delivered with `/shaka`.

## Cursor

Keep an existing, authenticated host configuration in place when preparing a
compatibility trial. Check its version and available controls before starting.
Native `SKILL.md` support is [documented for Cursor](https://cursor.com/docs/skills),
but shared file format alone does not prove V2 activation or safe execution.

The checked Cursor CLI exposes `--workspace`, `--add-dir`, `--sandbox`, and
`--plugin-dir`. Its public help has no direct skill-file option. The native sandbox
and V2 delivery have not been exercised, so these flags are not sufficient grounds
for a supported launch recipe.

Inspect the targets in the [official Cursor installation instructions](https://cursor.com/docs/cli/installation)
before installing. The inspected upstream installer creates both `agent` and
`cursor-agent` commands; those names can collide with another installed tool.
Prefer an existing signed-in host for a trial. The dedicated package startup check
did not change global command links or establish a general installation method.

## Usage is a separate capability

Follow [usage reporting](usage-reporting.md) for the supported reader, available
fields, and attribution limits. Record host/version separately from provider/model.
Preserve native reasoning settings and cache categories; similarly named settings
across hosts are not equivalent measurements.

Report missing data as `UNKNOWN`, and label shared or partial coverage. Publish
aggregate metadata only, without prompts, raw sessions, account details, or local
paths. Missing usage does not block an otherwise authorized merge, and CLI startup
does not establish model usage or savings.

# Model and token reporting

Each task reports the available native usage for its commits and contributions.
`UNKNOWN` means the available records do not establish a value; it never means zero.
The agent runs the trusted installed helper and includes its output in the PR,
or the final response when there is no PR:

```bash
shaka usage --commit FULL_COMMIT_SHA --contribution implementation
```

The helper reads the current host's records, Codex or Claude Code. When both hosts'
session context is present, pass `--host codex` or `--host claude-code`.

Contribution categories are `implementation`, `review`, `integration`, and
`shared-planning`. Supply several affected commit SHAs separated by commas when
the same work spans them. A report maps the whole selected interval to those
commits as **SHARED**; it never divides usage into invented per-commit amounts.
Retain that original mapping after squash merge and associate the merged SHA
without recounting the work.

## What the Codex reader includes

The reader uses the exposed current thread identifier to find one matching native
session beneath `CODEX_HOME` (default `~/.codex`). It checks the session metadata
before reading usage. The default selects the latest turn in that source. It
does not search unrelated transcripts or fall back to a parent's session.
Host context can be inherited, so this selection is shared source evidence and
does not establish which agent performed every response.

The Markdown contains the affected commits, contribution, observed response
interval, source version, configured provider/model/effort, and native token
categories. Cached input and reasoning output are subsets of input and output
in the tested Codex records; do not add them again. Cache writes and the native
total remain separate fields. Routed model stays UNKNOWN because these tested
local records do not establish the model that executed each response.

## What the Claude Code reader includes

The reader uses `CLAUDE_CODE_SESSION_ID` to find that session's transcript beneath
`CLAUDE_CONFIG_DIR` (default `~/.claude`), checks the session id inside the file, and
adds the session's subagent transcripts. The default selects the session's latest
turn together with the subagents started during it. Claude Code writes several lines
for one streamed response; the reader counts the last line, which carries the final
usage, once.

Rows report provider `anthropic`, the response's model as the routed model, the
recorded effort setting, and native token categories. Unlike Codex, Anthropic input
excludes cache reads and cache writes, so the three are separate amounts; reasoning
output is part of output. The configured model and native total stay UNKNOWN because
the transcript does not record them. A turn is a prompt id, so `--turn` selects
prompts, and every supplied file uses the first file's latest turn by default.

Claude Code documents its transcript format as internal and version-dependent. The
reader was exercised against desktop `2.1.270` and CLI `2.1.272` transcripts. It
matched an independent per-response aggregate for a session with a subagent, and
Claude Code's own totals for two CLI runs. Records it cannot read produce UNKNOWN.

## Coverage and fallback

The Codex adapter was exercised against desktop `0.154.0-alpha.6.2` and stable Codex
CLI `0.154.0` records. The fresh CLI consumer trial matched 14 responses to an
independent aggregate; repeating its source left the report unchanged. Unsupported
or unreadable records and missing fields produce UNKNOWN. Reports are PARTIAL
snapshots: active work, external reviewers, tool-model calls, and other agents
may add usage that is absent from the selected sources. Dollar cost, human active
time, and total historical consumption are not inferred from these tokens.

When host discovery is unavailable or several turns/contributors belong to the
work, the agent may supply repeated `--file PATH` and `--turn ID` options using
its private source context. Without `--turn`, each Codex file contributes its latest
turn, and Claude Code files use the first file's latest turn. For a session dedicated to one task, use `--all-turns` to include planning,
implementation, user answers, and merge turns together. It cannot be combined with
`--turn`. A fresh `shaka work` session starts with one task; if it later contains
unrelated work or inherited history, select relevant turns instead. Never include
other tasks just to obtain a bigger total. The visible report states its scope;
latest-turn output is not a whole-task total. Retain earlier non-overlapping task
reports when continuing in an existing conversation; replace only overlapping
snapshots. Include available review, retries, and subagent records. The helper counts
each response ID once across all supplied files, including forked/resumed copies;
it ignores cumulative snapshots. Conflicting counters, configuration, or interval metadata in response copies yield UNKNOWN.
Replace an earlier overlapping report instead of adding its totals again.

No report contains source paths, private turn/response IDs, prompts, transcripts,
or tool output. The helper reads local files and prints allowlisted aggregate
metadata; it neither modifies sessions nor publishes to GitHub. Review the report
for task coverage before publishing it. The visible coverage note stays outside
the expandable details; missing usage does not block a PR.

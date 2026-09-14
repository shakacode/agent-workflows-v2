# Model and token reporting

Each task reports the available native usage for its commits and contributions.
The agent runs the trusted installed helper and includes its output in the PR,
or the final response when there is no PR:

```bash
aw usage --commit FULL_COMMIT_SHA --contribution implementation
```

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

## Coverage and fallback

This adapter was exercised against Codex `0.154.0-alpha.6.2` records. Unsupported
or unreadable records and missing fields produce UNKNOWN. Reports are PARTIAL
snapshots: active work, external reviewers, tool-model calls, and other agents
may add usage that is absent from the selected sources. Dollar cost, human active
time, and total historical consumption are not inferred from these tokens.

When host discovery is unavailable or several turns/contributors belong to the
work, the agent may supply repeated `--file PATH` and `--turn ID` options using
its private source context. Without `--turn`, each file contributes its latest
turn. Include available review, retries, and subagent records. The helper counts
each response ID once across all supplied files, including forked/resumed copies;
it ignores cumulative snapshots. Conflicting response copies yield UNKNOWN.
Replace an earlier overlapping report instead of adding its totals again.

No report contains source paths, private turn/response IDs, prompts, transcripts,
or tool output. The helper reads local files and prints allowlisted aggregate
metadata; it neither modifies sessions nor publishes to GitHub. Review the report
for task coverage before publishing it. The visible coverage note stays outside
the expandable details; missing usage does not block a PR.

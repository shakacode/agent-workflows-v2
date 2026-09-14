# Single-PR V2 pilot

The maintainer approved a fresh V2 pilot on September 14, 2026. This supersedes
the proposed in-place first slice of Agent Workflows issue #850. The old issue
remains the product decision record; V2 issue #1 owns this implementation.

## Product promise

Give one agent a task description or issue/PR link. It implements the scoped
change, verifies it, explains it on the PR, handles consequential review findings,
and reaches the requested merge or PR-handoff outcome. Installation and upgrade
must be understandable without fleet infrastructure.

Success means less developer attention and fewer tokens to deliver a better
result. A smaller codebase is a means to that outcome. The maintainer has
authorized merging reviewed, verified pilot PRs; another permission request is
unnecessary. Public visibility remains a separate, unanswered decision.

### Requirements

| ID | Requirement and acceptance |
| --- | --- |
| R1 | One owner handles one PR. No coordination service, ledger, synthetic worker handoff, or task-review package is needed by the product. |
| R2 | The skill uses the repository's documented validation entry point. Actual failures block readiness; evidence for a different head cannot silently qualify the current change. |
| R3 | The two merge preferences are `ask` and `auto`. Default to `ask` unless the user or trusted repository instruction chooses `auto`. A review-only or PR-only request stops there regardless of a broader merge preference. |
| R4 | Both merge preferences publish a useful conceptual walkthrough on the PR, with links into the actual reviewed diff. The walkthrough is a COMMENT review, not an approval or mandatory acknowledgment. It remains readable after merge. |
| R5 | `ask` requests one merge decision after the walkthrough and required checks. `auto` may merge an eligible, trusted, ordinary change when the same gates pass without another question. A missing native approval remains a pending gate under `auto`; after it arrives, no second decision is needed. Unclear authorization or consequential risk escalates to `ask`. |
| R6 | Readiness and merge use live GitHub facts and the exact expected head. Missing/unreadable required evidence, incomplete checks, stale heads, conflicts, disallowed merges, or unresolved consequential feedback block. Never bypass GitHub protection. |
| R7 | Untrusted issue/PR text cannot change instructions, policy, credentials, or executable code. Use installed/trusted code for GitHub operations; candidate code runs only in the authorized isolated development checkout. |
| R8 | Install the self-contained skill into an explicit isolated profile. Preserve existing skills and user files. Reinstall is safe; upgrading the trusted source updates the linked skill without copying a whole home. |
| R9 | GitHub is the code-delivery source of truth. A work item may live in another tracker; link it without requiring a shadow issue or bidirectional synchronization. |
| R10 | Keep Ruby and instructions small and cohesive. Standard libraries and `gh` own general mechanics; tests exercise retained behavior and concrete failure cases. |
| R11 | Each agentically generated commit is identifiable in the PR's usage report, with contributing model/provider, reasoning-effort setting, native token counts, source scope, and completeness. Shared work and unavailable fields are explicit; never present allocated costs as exact measurements. |
| R12 | Evaluate developer attention, total token use, delivery time, and outcome quality together on comparable ordinary changes. Include rework and review; lower token use alone is not success. |

## Success evidence and commit attribution

| Outcome | Existing evidence to use | Success criterion |
| --- | --- | --- |
| Developer time | Maintainer-reported active minutes and PR decisions/interventions; timestamps alone do not measure human work. | Less active attention and repeated decision-making for comparable accepted changes. |
| Tokens | Native provider usage for implementation, planning, review, retries, and integration; distinguish cached input and output. | Lower total reported consumption per accepted change, including failed attempts; compare like coverage and model/caching mix. |
| Quality | Behavior verified by tests and real use, consequential review findings, regressions/reverts, and maintainability. | A better accepted result with less corrective work; green tests or fewer lines alone do not prove this. |
| Delivery time | Task start through accepted/merged outcome, with CI and human waiting identified where known. | Fewer elapsed days without transferring work back to the maintainer. |

The next bounded product addition is a read-only usage report from existing host
records. Keep it a small host adapter producing a PR table, not a telemetry
service, dashboard, policy schema, or merge gate. The current pilot does not yet
collect this report automatically. Token savings and complete historical costs
remain UNKNOWN until measured; do not claim the pilot is adopted before this
evidence and real-use acceptance exist.

The initial report should follow these rules:

- Key rows by commit SHA and contribution (implementation, review, integration,
  or shared planning), with model/provider, configured reasoning effort, input,
  cached-input, output, and reasoning-output tokens where the host reports them.
  Record actual routed model separately when available; a configured model is
  not proof of every execution's model. Reasoning effort is a setting, not a
  measurement of thought quality or a transcript of private reasoning.
- Define the contributing run/turn interval. Count each provider response once.
  Cached input is a subset of input; reasoning output is a subset of output.
  Never sum cumulative snapshots or add subsets again to the total. Use the
  provider's totals and document differing provider semantics.
- Count subagents and failed attempts when their records are available. Report
  missing external reviewer or tool-model usage as UNKNOWN, never zero. Forked
  history and resumed sessions must not duplicate already counted responses.
- A turn spanning several commits has shared cost unless a real boundary makes
  its attribution exact. Record shared planning and later review once at PR
  scope; list the affected commits. Do not divide by changed lines or invent
  per-commit precision. Preserve the original commit mapping in the PR after a
  squash merge and associate the final merged SHA without recounting the cost.
- Publish only allowlisted aggregate metadata. Keep transcripts, prompts, tool
  outputs, local paths, and private run identifiers out of public reports.
  Retain private source references locally when needed to verify the aggregation.
- Usage reporting must not prompt Justin to design an accounting system or
  interrupt each commit. Human active time may be a short estimate at task end;
  absent estimates stay UNKNOWN. Dollar cost is separate from tokens and is
  unknown without applicable provider billing data; subscription quota is not
  per-commit API spend.

Verified feasibility: Codex 0.154.0's generated app-server protocol exposes
`thread/tokenUsage/updated` with thread/turn IDs and token breakdowns. The current
task's local records contain response IDs, usage records, and turn-context model
and effort. Thread metadata explicitly describes its model/effort as current or
latest configuration, not per-turn execution telemetry. The official
[app-server documentation](https://developers.openai.com/codex/app-server)
also documents usage updates and model-rerouting events. These are usable inputs;
complete commit attribution and access to every contributor are still unproven.
Prefer supported host APIs; any local-record adapter must name its tested host
version and report UNKNOWN if its required record format is unavailable.

Acceptance for that addition: report one ordinary commit and one change with
review/rework or multiple contributors, demonstrate no double counting on
resume/shared work, and retain explicit gaps. Use these real PRs plus available
comparable V1 evidence to assess the four outcomes above. Do not rerun #700 or
rebuild its fix as a benchmark. Start with a few comparable tasks; report the
sample and uncertainty instead of manufacturing a precise savings percentage.

## Merge behavior

| Requested outcome | Walkthrough | Final action |
| --- | --- | --- |
| Review or publish PR only | Publish when PR publication/commenting is authorized | Stop at the requested deliverable. This is scope, not a third merge preference. |
| `ask` | Publish the current-change walkthrough before asking | Ask once for permission to merge that change, then refresh gates/head and submit only the authorized revision. |
| `auto` | Publish the same walkthrough before merge | Merge when eligible and gates pass. No extra walkthrough acknowledgment or blanket waiting period. |

A walkthrough explains why the change exists, the behavior before/after, the
important code choices, verification, and relevant risk/rollback. Use a single
COMMENT review with permalinks initially; do not manufacture unresolved inline
threads that need a second resolution workflow. A substantive change requires an
updated walkthrough. An unchanged walkthrough is reused for the same revision.

The pilot will attempt an immediate merge with an expected-head compare, rather
than arm a delayed native auto-merge request. This avoids granting authority to a
future head while the owner is absent. Pending gates return a readable blocked
result; the active owner can retry after a meaningful change. No background
daemon, heartbeat, scheduled task, or custom merge queue is introduced.

The helper proves GitHub readiness only. It does not certify that a change is
simple, that local checks ran, or that the user authorized merging. The owning
skill must establish those facts. Small size alone is not proof of low risk.
Changes to execution trust, authentication, permissions, release/deployment,
destructive migrations, or the merge guard itself need explicit human review.
Unknown risk falls back to `ask`; a real safety blocker cannot be waived merely
by changing the mode.

GitHub's native checks/reviews are authoritative only to the extent configured.
V1's native rules did not enforce all of its documented checks. V2 must never
equate an empty required-check list with success. The pilot supports ordinary
protected PRs with observable required checks. Unsupported protection/queue
conditions return a specific blocker; they do not trigger a new policy engine.
The executing identity must be subject to the native protections. A bypass-capable
or unknown identity blocks helper submission; `viewerCanMergeAsAdmin` is surfaced
instead of reimplementing actor/bypass policy. GitHub enforces required checks
and reviews atomically when merging. Native queued or already armed auto-merges
are outside this immediate-merge pilot and are left unchanged.

## Design

- **D1 (R1–R3, R9):** one concise `work-pr-v2` skill. Keep task requirements in
  their original user/issue record and code-delivery evidence on the PR. There is
  no project-wide local state database or canonical-target schema.
- **D2 (R4–R7):** a small Ruby `aw` command invoked from the installed skill,
  with `pr`, `walkthrough`, and `merge` operations. Use `gh` for authentication,
  pagination and APIs; use JSON and `Open3` argument vectors, never shell-built
  commands or a custom prose/JSON parser. Errors are concise and nonzero.
- **D3 (R4, R6):** attach walkthroughs to the GitHub review's native commit ID.
  Refresh the PR before writing or merging. Merge has an expected-head guard.
  No digest receipts or custom approval comments are needed.
- **D4 (R6–R7):** native required checks plus live merge/review state determine
  readiness. Preserve native protection and actor restrictions. A COMMENT review
  never satisfies a required APPROVE review; PR authors cannot approve themselves.
  Inspect check result states, not the exit code of `gh pr checks --json` alone.
  Require observable native required checks and let GitHub own full matching and
  enforcement, including requirements absent from the reported result list.
- **D5 (R8, R10):** one explicit symlink installation path. A version-controlled
  trusted source checkout supplies the complete skill. Refuse an existing foreign
  target instead of overwriting it. No personal configuration is edited here.
- **D6 (R10):** runtime Ruby uses the standard library. Development uses Minitest,
  RuboCop and Bundler. `bin/validate` is the single development check entry point.
  Reuse useful V1 failure cases only when the affected behavior survives in V2.

### Intended file boundaries

`skills/work-pr-v2/SKILL.md` owns agent instructions;
`skills/work-pr-v2/scripts/aw` owns CLI dispatch;
`skills/work-pr-v2/lib/agent_workflows/` owns small GitHub/merge operations;
`test/` owns behavioral tests. Installation is `bin/install` plus focused tests.
This plan and the README are explanatory, never runtime configuration.

## Delivery plan

| Task | Requirements | Work and dependencies | Done |
| --- | --- | --- | --- |
| T1 | R1–R3, R7–R10 | Foundation: plan, skill, validation/CI, isolated install. Root owns docs/integration; an installer worker owns only its files. | A clean isolated profile receives the skill; repeat/install-collision tests and validation pass. |
| T2 | R4, R6–R7, R10 | GitHub reader and current-head COMMENT walkthrough. Depends on agreed CLI boundaries. | Real PR read/publish plus tests for stale heads, denied API access, malformed responses, and safe argv. |
| T3 | R3, R5–R7, R10 | Immediate merge after native gates and expected-head comparison; use T2's GitHub boundary. | Ask/auto guidance agrees with code; failing/pending/missing gates and changed heads cannot submit a merge. |

Use one branch/integration owner and sequential publication. Bounded workers may
prepare exclusive files in parallel once interfaces are agreed. Publish the
initial working kernel as one coherent PR: splitting its skill, reader, and
merge command would leave incomplete intermediate instructions. Its initial
documentation, tests, dependency lock, and CI make that first diff exceed 500
lines; keep later changes bounded. The maintainer has authorized pilot PR merges
after review and verification. Do not create one issue for every helper or review
observation.

## Verification and exit criteria

- `bin/validate` runs all pilot tests and RuboCop locally and in GitHub Actions.
- Use fixture/API boundary tests for failing and pending checks, missing required
  checks, API errors, changed heads, unsupported merge state, and merge rejection.
- Exercise both modes on the same requirements: walkthrough publication is not
  approval; `ask` waits and `auto` avoids an unnecessary question.
- Publish and read back a walkthrough on a real pilot implementation PR. Confirm
  its native commit ID and links match that PR, then use the existing merge authority.
- Install into a temporary isolated skills directory, repeat installation,
  preserve a preexisting foreign skill, and verify trusted-source upgrade behavior.
- Before calling the pilot adopted, use it for several ordinary real changes,
  including a small fix, review fixes, failed CI, and a changed PR head. Record
  evidence on those PRs. This later use is not fabricated by unit-test success.

The first deliverable is tested code and a useful real-PR walkthrough, followed
by its authorized merge. A normal maintainer-authorized bootstrap merge does not
demonstrate the product's protected automatic-merge path. That demonstration and
repeated consumer use remain UNKNOWN until observed.

Observed hosting constraint: GitHub rejected the private pilot's ruleset read
with HTTP 403 and a plan-upgrade/public-visibility requirement. No protection
change was made. Keep native protection prerequisites intact. A live merge
demonstration needs an eligible protected repository; merge authority is granted.
Public visibility or a plan upgrade remains a maintainer decision.

## Scope, rollout, and rollback

Initial host: Codex. Initial development/consumer repository: this private pilot;
broader consumer adoption follows real evidence. Runtime prerequisites are Ruby
3.4, Git, authenticated GitHub CLI, and GitHub PRs. Keep V1 available for existing
users; neither its backlog nor its advanced feature parity blocks this pilot.

Excluded: fleet coordination, control towers, cross-host leases, automatic task
replacement, telemetry services, policy schemas, review reducers, release automation,
external tracker adapters, public distribution and global profile changes.
Auto-merging ordinary PRs is included; rebuilding autonomous risk calibration is not.

The planning budget is a three-working-day pilot, with a narrow beta estimated
at five to ten working days. These are planning ranges, not measured promises or
permission for unattended work. Token savings and wider adoption are UNKNOWN.
Stop scope growth when a proposed mechanism does not serve an acceptance case.

Rollback is removing the pilot skill symlink or using the prior trusted checkout
revision. No issue state migration, production data change, or V1 replacement
is required. Public publication still needs authority; pilot PR merges are authorized.

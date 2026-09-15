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
unnecessary. The maintainer also approved public visibility on September 14.

### Evaluate value before adding scope

For a proposed product capability, assess its **user problem, smallest useful
solution, build cost, recurring burden, acceptance evidence, and disposition** in
these existing tables. Prefer deleting a step or reusing repository instructions,
native host/GitHub capabilities, or trustworthy libraries. An unfinished V1 PR
alone does not establish value. Reassess product scope when evidence changes;
ordinary consumer PRs do not need to maintain this assessment.

The Requirements table owns acceptance. Design records implementation choices;
the rollout table orders work. Use the [existing success criteria](#success-evidence-and-commit-attribution)
to assess developer attention, total tokens, delivery time and quality together,
including retries/review. These sections serve different questions, not competing
approval processes. Missing benefit measurements remain UNKNOWN.

**Apparent complexity: build / recurring.** L means little new implementation or
ongoing work; M means a bounded integration or repeated human/maintenance work;
H means a subsystem, broad compatibility or substantial recurring burden.
These are rough estimates, not measured effort or a numeric ranking: do not sum
ratings or use them as a pass/fail threshold. Use UNKNOWN for an unbounded design.
Count extra questions, context, code/dependencies, checks, reports and host upkeep,
including interactions with existing features. Conditional UI evidence is not work
for every PR.

**Keep, simplify, defer, or retire:** preserve essential safety capabilities;
simplify expensive implementations; defer unproven conveniences; retire demonstrated
duplication or burden without sufficient benefit. For optional features, consider
doing nothing and name what evidence would justify reconsideration. For trust,
current-head verification, merge authority and required checks, reduce duplication
without weakening the invariant. No new tracker, scoring system, telemetry,
per-PR checklist or approval loop is needed.

### Requirements

The acceptance column retains the product contract. Problems, complexity and
recommendations are an initial assessment of the smallest stated solution, not
a claim that implementation or real-use acceptance is complete.

| ID | Problem to solve | Requirement and acceptance | Apparent complexity: build / recurring | Recommendation and limit |
| --- | --- | --- | --- | --- |
| R1 | Maintainers lose time coordinating agents and recovering unclear ownership for a small change. | One owner handles one task, normally through one PR. Split oversized work into the smallest useful PRs; keep dependencies and remaining scope on the existing work item/PRs. No coordination service, ledger, synthetic worker handoff, or task-review package is needed. See [task splitting](working-with-your-agent.md#when-a-task-needs-several-prs). | L / L solo; H / H fleet coordination. | Keep one owner. Split only for useful delivery boundaries; defer fleet machinery. |
| R2 | A generic workflow runs the wrong commands or ignores a repository’s established policy. | Preserve each repository's command/policy seam: trusted `AGENTS.md`, existing `.agents/bin/` commands and `.agents/agent-workflow.yml` where referenced. Use its validation entry point and local conventions. Actual failures block readiness; evidence for a different head cannot qualify the current change. | L / L for declared commands; M / M for undocumented setup. | Keep the seam; reuse or minimally document it. Avoid a policy interpreter or universal config migration. |
| R3 | The agent either surprises the maintainer by merging or repeatedly asks for authority already given. | The two merge preferences are `ask` and `auto`. If authority is unset, ask early which the user wants for this task; default to `ask` without an answer. Reuse established authority. A review-only or PR-only request stops there regardless of a broader merge preference. | L / L: one scoped choice, reused. | Keep Ask/Auto and request-only scope. Treat R3/R5 as one user interaction, not two approval systems. |
| R4 | A maintainer cannot quickly understand what changed, why, or what was verified. | Both merge preferences publish a useful conceptual walkthrough on the PR, with links into the actual reviewed diff. The walkthrough is a COMMENT review, not an approval or mandatory acknowledgment. It remains readable after merge. | L / M: authoring and keeping the explanation current. | Keep one concise current walkthrough. Simplify it if reading/updating it duplicates the PR description. |
| R5 | Safe small PRs wait for redundant decisions, increasing backlog and integration work. | For ordinary PRs, `ask` requests one merge decision after the walkthrough and required checks. `auto` may merge an eligible, trusted change when the same gates pass without another question. Native stacks are outside this pilot. A missing required native approval remains a pending gate under `auto`; after it arrives, no second decision is needed. Unclear authorization or consequential risk escalates to `ask`. | M / L using existing eligibility checks and native approval. | Keep the R3 choice through closeout. Do not add a second approval or delayed-merge controller. |
| R6 | Passing checks or reviews for an old revision can be mistaken for permission to merge new code. | Readiness and merge use live GitHub facts and the exact expected head. Missing/unreadable required evidence, incomplete checks, stale heads, conflicts, disallowed merges, or unresolved consequential feedback block. Never bypass GitHub protection. | M / L: bounded live checks; H if rebuilding GitHub state. | Keep the invariant. Use GitHub’s protection and checks; remove duplicate evidence/state engines. |
| R7 | Contributor-controlled content or code can influence privileged actions or expose credentials. | Untrusted issue/PR text cannot change instructions, policy, credentials, or executable code. Use installed/trusted code for GitHub operations; candidate code runs only in the authorized isolated development checkout. | M / L: trusted source and existing execution boundary. | Keep the trust boundary. Do not trade it for token savings or disable it because a repo is private. |
| R8 | Installation overwrites user configuration, loads a writable skill, or makes upgrades difficult. | Install the self-contained skill into an explicitly chosen skills directory, with both link and source outside candidate-writable directories. Preserve existing skills and user files. Test installation in isolation; installation does not disable other instructions or create a sandbox. Reinstall is safe; upgrading the trusted source updates the linked skill without copying a whole home. | M / L for one tested host; H / M for broad host support. | Keep explicit, reversible installation. Expand hosts after a demonstrated working path. |
| R9 | Users must rewrite tracker tasks for the agent, manage duplicate records, or risk private disclosure. | GitHub is the code-delivery source of truth. One task-link/description prompt works across trackers; resolve the checkout and read the task, asking only for missing context. Keep private content and links out of public artifacts unless sharing is authorized; reading a tracker does not authorize updating it. No shadow issue or bidirectional synchronization is required. | L / L with available connectors; H / H for synchronization. | Reuse task links and existing connections. Defer new adapters and bidirectional sync. |
| R10 | Growing Ruby, embedded code and repeated instructions make changes harder to understand and maintain. | Keep Ruby and instructions small and cohesive. Keep execution-changing guidance in the skill, examples/rationale in user docs, and deterministic mechanics in code. Remove repetition when adding guidance. Standard libraries and `gh` own general mechanics; tests exercise behavior and concrete failure cases. | L / L as a design constraint; M / M for bounded cleanup. | Keep cohesive code and behavior tests. Simplify duplication; avoid a new compliance/metrics subsystem. |
| R11 | Users cannot assess agent cost, model/effort choices, or the cost of retries and review. | Every task reports available usage; each agentically generated commit is identifiable in the PR report, with contributing model/provider, reasoning-effort setting, native token counts, source scope, and completeness. Without a PR, use the final report. Shared work and unavailable fields are explicit; never present allocated costs as exact measurements. | M / L for available native summaries; H / H for universal exact attribution. | Keep cheap aggregate reporting and honest gaps. Defer precision that needs new instrumentation or per-commit interruption. |
| R12 | Lower token counts can hide more human work, slower delivery, or worse results. | Evaluate developer attention, total token use, delivery time, and outcome quality together on comparable ordinary changes. Include rework and review; lower token use alone is not success. | L / M for a small manual comparison using existing records. | Keep a bounded comparable sample. Defer dashboards and continuous benchmarking; no savings claim without evidence. |
| R13 | Dense agent messages and late questions force repeated reading, clarification and corrective work. | One owner explains outcomes, reasons, blockers, and decisions using familiar terms and enough context for the first reading. Follow task/repo writing preferences without requiring a separate clarification skill. Supporting evidence uses expandable PR details; important risks and gaps remain visible. Ask consequential questions when needed, with a recommendation. See [working with your agent](working-with-your-agent.md). | L / L for concise defaults; M recurring if every task gets a questionnaire. | Keep early consequential questions and plain outcomes. Remove unnecessary templates, jargon and repeated status. |
| R14 | Green tests can miss the actual failure or a broken visible interaction. | Behavior changes follow red-green-refactor using the repo's existing tests. Observe the relevant failure before the fix; document useful before/after verification when automation is impractical. Visible changes have inspected screenshots and short video when interaction or timing matters, with safe reviewer-accessible evidence tied to the tested revision. See [tests and visual evidence](verification.md). | M / M for relevant tests/screenshots; H recurring for blanket video/full-suite repetition. | Keep meaningful red/green and inspected UI evidence. Use video when timing/interaction warrants it; avoid unrelated repeated verification. |

## Success evidence and commit attribution

| Outcome | Existing evidence to use | Success criterion |
| --- | --- | --- |
| Developer time | Maintainer-reported active minutes and existing task/PR discussion: reading burden, repeated questions, decisions, late clarification, and corrective work. Timestamps alone do not measure human work. | Less active attention, avoidable waiting, and repeated explanation for comparable accepted changes; decisions and outcomes understandable without opening detailed evidence. |
| Tokens | Native provider usage for implementation, planning, review, retries, and integration; distinguish cached input and output. | Lower total reported consumption per accepted change, including failed attempts; compare like coverage and model/caching mix. |
| Quality | Behavior verified by tests and real use, consequential review findings, regressions/reverts, and maintainability. | A better accepted result with less corrective work; green tests or fewer lines alone do not prove this. |
| Delivery time | Task start through accepted/merged outcome, with CI and human waiting identified where known. | Fewer elapsed days without transferring work back to the maintainer. |

The [read-only usage reader](usage-reporting.md) uses existing Codex host records
and produces a PR table. The skill runs it as part of normal reporting; there is
no telemetry service, dashboard, policy schema, or merge gate. Token savings and
complete historical costs remain UNKNOWN until measured; do not claim the pilot is adopted before this
evidence and real-use acceptance exist.

The initial report should follow these rules:

- Key rows by commit SHA and contribution (implementation, review, integration,
  or shared planning), with model/provider, configured reasoning effort, input,
  cached-input, output, and reasoning-output tokens where the host reports them.
  Record actual routed model separately when available; a configured model is
  not proof of every execution's model. Reasoning effort is a setting, not a
  measurement of thought quality or a transcript of private reasoning.
- Define the contributing run/turn interval. Count each provider response once.
  In Codex's observed records, cached input and reasoning output are subsets of
  input and output respectively. Other providers can report cache reads/writes
  separately. Preserve native categories and their meanings; never sum cumulative
  snapshots, add subsets again, or apply one provider's total formula to another.
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
  Put the detailed table in a labeled PR `<details>` block, with material coverage
  gaps in the visible summary. Collapsing is a reading aid, not access control or
  a reduction in tokens when the same content is loaded by an agent.
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

## Repository seam

Repository adaptation is part of the kernel. The host reads trusted `AGENTS.md`
and follows its references to local commands and policy. Existing consumers can
retain `.agents/bin/<name>` and `.agents/agent-workflow.yml`; repos with direct
command declarations need no new files. Preserve setup, validation, focused
checks, base branch, review, changelog/release conventions, and scoped merge
authority. Do not copy the pilot's Ruby commands into other repositories.

Resolve only the capabilities needed for the task. Missing optional capabilities
are n/a; a missing required command or conflicting policy needs clarification.
Candidate edits to the seam cannot lower this run's trusted requirements. Native
GitHub checks, approvals, current-head verification, and explicit authority remain
required regardless of what a candidate configuration says.

This is agent-consumed configuration, not a new Ruby policy interpreter. V1's
coordination and autonomous-control-plane fields do not activate those features
in V2. No consumer migration, new schema, seam validator, or additional config
layer is required by this change. Full V1 policy-key compatibility remains out
of scope; incompatible required behavior should be explained before proceeding.

Verified declaration examples: this pilot's `AGENTS.md` directly names
`bin/validate` and `bundle install`; the public `agent-workflows-com` instructions
point to `.agents/bin/` and `.agents/agent-workflow.yml`, whose validation script
runs the site's npm build and adoption checks. Reading those declarations proves
command discovery, not successful V2 delivery in that consumer. Real adoption
must exercise unlike repositories and preserve their existing command/policy
choices. Complete cross-repository compatibility remains UNKNOWN until tried.

## Host boundary

Recommendation: one portable kernel from the start, with Codex as the first
reference host. Validate Claude Code second and Cursor third. Supporting the
skill format is distinct from demonstrating the complete workflow and complete
usage attribution. Initial scope is local execution; cloud/remote packaging is
not implied by a successful local install.

| Host | Initial product commitment | Evidence and remaining work |
| --- | --- | --- |
| Codex | Reference pilot; first usage reader. | Installation, Ruby helpers, and real PR operations have been exercised. The native reader is tested against desktop and stable CLI records. A fresh CLI task implemented and verified the Astro website guides through the consumer seam. |
| Claude Code | Compatibility target; next workflow/usage trial. | Native skills and request metadata are documented. Actual V2 activation, complete PR delivery, and usage coverage remain UNKNOWN until tried. |
| Cursor | Compatibility target; validate after Claude Code. | Native skills and session/model metadata are documented. Full V2 delivery and per-request token/effort coverage remain UNKNOWN; do not promise reporting parity from skill compatibility alone. |

The abstractions should follow existing differences:

- Keep one `SKILL.md`, installer, validation entry point, and GitHub/merge code.
  Installation takes an explicit trusted directory; invocation and trusted
  instruction discovery may need a short host-specific setup note. Do not fork
  the workflow or copy policy into three host-specific versions.
- Keep usage reading separate from code delivery. Start with a small concrete
  Codex reader. Inspect a real Claude Code request sample before stabilizing the
  report interface; extract shared aggregation only when the second reader is
  implemented. No generic agent superclass, orchestration protocol, or plugin
  registry is needed for the first reader.
- Record host and version separately from provider and model: an editor/runner
  name does not establish the model or billing provider. Preserve native reasoning
  settings; `high` in two products is not an equivalent amount of computation.
  Retain unavailable fields and data coverage explicitly rather than inventing
  a universal effort scale or silently assigning zero tokens.
- The same GitHub gates, current-head verification, walkthrough, and merge
  authority apply on every host. Missing usage data remains a reporting gap.
  A host only gains a tested-support claim after an isolated installation and
  ordinary PR exercise, including failed checks, changed head, and ask/auto
  stopping behavior. Report usage support separately, using real native records.

Official evidence checked September 14: [Codex skills](https://developers.openai.com/codex/skills),
[Claude Code skills](https://code.claude.com/docs/en/skills), and
[Cursor skills](https://cursor.com/docs/skills) all use `SKILL.md`. Their documented
local project roots include `.agents/skills`, `.claude/skills`, and
`.cursor/skills` respectively; each host has additional discovery rules.
[Claude Code request monitoring](https://code.claude.com/docs/en/monitoring-usage)
documents model, effort, request IDs, and separate input/output/cache categories.
[Anthropic caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
uses separate cache usage fields, so Codex's subset convention cannot be assumed.
[Cursor CLI output](https://cursor.com/docs/cli/reference/output-format) and
[hooks](https://cursor.com/docs/hooks) expose session/model metadata; these sources
do not establish complete token/effort attribution to every V2 commit. These are
documentation findings, not a claim that either host has been tested here.

This sequence gives us a working product sooner and checks the second host early
enough to catch Codex-specific assumptions. Full three-host support on day one
would add installation, permission, session, and usage compatibility work before
the ordinary flow has established its value. Keep that work in the existing pilot
scope and admit it sequentially; no separate host backlog trackers are needed.

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
When editable, superseded walkthroughs retain their evidence collapsed beneath a link to the current one; see
[walkthrough guidance](working-with-your-agent.md#keep-one-current-walkthrough).

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

- **D1 (R1–R3, R9):** one shared workflow exposed as `$sw`, with `$aw` compatibility. Keep task requirements in
  their original user/issue record and code-delivery evidence on the PR. There is
  no project-wide local state database or canonical-target schema.
- **D2 (R4–R7):** a small Ruby `sw` command (also available as `aw`) invoked from the installed skill,
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

`skills/aw/SKILL.md` owns agent instructions;
`skills/aw/scripts/aw` owns CLI dispatch;
`skills/aw/lib/agent_workflows/` owns small GitHub/merge operations;
`test/` owns behavioral tests. Installation is `bin/install` plus focused tests.
This plan and the README are explanatory, never runtime configuration.

## Delivery plan

Apply R1's [splitting guidance](working-with-your-agent.md#when-a-task-needs-several-prs)
to larger work.

The maintainer approved the next feature set on September 14: explicit TDD and
visual evidence, native usage reporting, a real consumer first-use trial, gem
packaging and the V2 documentation website, then Claude Code and Cursor validation.
Use the WIP V2 skill for this work. Deliver bounded PRs in that order, allowing
independent preparation while one owner integrates and publishes. Issue #1 remains
the implementation record; do not create a second feature tracker.

Use the website as a proposed consumer trial so the work also delivers useful V2
documentation. Verify the consumer's own setup and checks, and capture the rendered
result. Host compatibility is claimed only to the extent actually exercised;
unavailable access or unsupported isolation remains an explicit gap. Package and
test locally before any registry release. Website production publication remains
a separate decision after a reviewable preview.

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
demonstrate the product's protected automatic-merge path. That path was subsequently
observed on [PR #3](https://github.com/shakacode/workflows/pull/3) and the
later pilot PRs, with current-head walkthroughs and enforced native checks.
Repeated consumer use remains required before claiming broader adoption.

The private-hosting restriction was resolved by the authorized public visibility
change on September 14. The active [main ruleset](https://github.com/shakacode/workflows/rules/23252676)
requires PRs and an up-to-date `validate` check from GitHub Actions. It has no
bypass actors and blocks force-push and deletion. The required approving-review
count is zero for the single-user pilot; the skill still handles consequential
review and risk. Record protected automatic-merge evidence on the ordinary PR
that exercises it rather than treating the ruleset's existence as proof.

## Ruby packaging

The root `Gemfile` and `Gemfile.lock` manage development dependencies; runtime
helpers use standard libraries. `shakacode-workflows.gemspec` packages the complete
skill and thin `sw` / `aw` / `install-agent-workflows` executables that reuse the existing
implementations. The provisional version is `0.1.0.pre.1`.

The package test builds and installs the actual artifact into a separate gem home,
runs its helper and installer outside the source checkout, then removes it.
Existing installer tests cover repeat installation, collisions, and source updates.
The [packaging guide](packaging.md) explains local trials and the fact that a
manually linked skill retains its selected gem version until explicitly relinked.
Do not add the pilot to application bundles or export its test gem environment.

Registry release remains out of scope. Explicitly requested user skill installation
uses the same installer without changing other settings. License and
registry publication approval remain outstanding; packaging does not invent that
authority. Keep source installation available until the complete packaged first-use
experience is verified. Use standard RubyGems mechanics rather than a release framework.

## Documentation website

Make the ordinary workflow understandable before asking users to learn its
implementation. The README is the short entry point; user guides explain tasks
and decisions; this plan remains a contributor document. The installed skill owns
agent instructions. The website should render the user guides without becoming
another source of workflow policy.

Observed September 14, 2026: [workflows.shakacode.com](https://workflows.shakacode.com/)
already has a [docs section](https://workflows.shakacode.com/docs/). Its homepage says
coordination is optional, but its main sequence still emphasizes planning,
splitting work, review, and audit. The public
[site repository](https://github.com/shakacode/agent-workflows-com) uses Astro and
documents deployment to Cloudflare Pages. Current source paths include
`src/pages/index.astro`, `src/pages/docs/`, `src/layouts/Doc.astro`, and
`src/components/BatchLifecycle.astro`.

[ShakaStack](https://shakastack.com/) presents products by the job they do and
links to their documentation. [Shakapacker's docs](https://shakapacker.com/docs/)
offer task navigation for installation, configuration, upgrades, and troubleshooting.
Its [site repository](https://github.com/shakacode/shakapacker.com) uses Docusaurus
and keeps canonical Markdown in the product repository. Adopt those user-facing
conventions and source ownership; retain the existing Astro site for the first
V2 pages. A framework migration is unnecessary for this content change.

The intended reading path is:

1. **Start here:** what the product does, pilot status, supported hosts, isolated
   installation, and one copyable ordinary-task example.
2. **Work one PR:** questions before/during work, progress updates, the walkthrough,
   and Ask or Auto. Show a short conversation and expandable evidence.
3. **Use and maintain it:** upgrade/rollback, common blockers with next actions,
   and model/token reporting with its actual availability and gaps.
4. **Advanced and V1:** existing multi-agent coordination, fleet tooling, and V1
   docs, clearly labeled as separate from the V2 pilot.

After the current README/communication improvement, keep website delivery to two
bounded steps under existing issue #1; each should preferably stay below 500 lines:

- **Publish a V2 entrance:** in `agent-workflows-com`, add a clearly labeled pilot
  link and `/docs/v2/` entry using the existing doc layout. Lead the V2 journey
  with “Give your agent a task. Get a verified PR and a clear explanation.” Show
  task → implement and clarify → verify → explain → Ask/Auto; questions can occur
  throughout. Keep V1 URLs working and label advanced links. Stop at a previewable
  entrance and guide, without replacing the V1 installation instructions.
- **Complete the task guides:** keep maintained user-guide Markdown in V2 `docs/`
  and have the site build read an explicit set of those pages from a recorded V2
  revision. Use the site's Markdown renderer; avoid hand-maintained copies or a
  custom documentation framework. Add shared task navigation, readable mobile
  layouts, accessible details blocks, and source/edit links. Use a maintained
  search component if the guide collection needs search; do not build a search
  service. The exact cross-repository build wiring remains UNKNOWN until inspected
  during implementation. Stop when a new user can install, complete one PR,
  understand a question or blocker, and find the relevant evidence.

Verify website changes with its existing build/link checks and a browser walkthrough
of that reading path, including keyboard access, collapsed content, and preserved
V1 links. Update checks that enforce the old journey rather than pinning new prose.
Preview before production publication. Rollback is reverting the site PR; product
installation and existing V1 documentation remain usable. Website implementation
and deployment have not happened in this documentation change. Adoption timing,
measured reading-time savings, and broader host support remain UNKNOWN.

## Scope, rollout, and rollback

Initial reference host: Codex, followed by Claude Code and Cursor as described
above. Initial development/consumer repository: this public pilot; broader
consumer adoption follows real evidence. Runtime prerequisites are Ruby
3.4, Git, authenticated GitHub CLI, and GitHub PRs. Keep V1 available for existing
users; neither its backlog nor its advanced feature parity blocks this pilot.

Excluded: fleet coordination, control towers, cross-host leases, automatic task
replacement, telemetry services, policy schemas, review reducers, release automation,
external tracker adapters, registry distribution and unrelated global profile changes.
Auto-merging ordinary PRs is included; rebuilding autonomous risk calibration is not.

The planning budget is a three-working-day pilot, with a narrow beta estimated
at five to ten working days. These are planning ranges, not measured promises or
permission for unattended work. Token savings and wider adoption are UNKNOWN.
Stop scope growth when a proposed mechanism does not serve an acceptance case.

Rollback is removing the pilot skill symlink or using the prior trusted checkout
revision. No issue state migration, production data change, or V1 replacement
is required. Public source publication and reviewed, verified pilot PR merges
are authorized. The maintainer also requested `$sw` in the Codex app; installation
of that one user skill is authorized. Registry releases remain out of scope.

### Priorities for retiring ordinary V1 use

Use this plan and existing issue #1 for V2 acceptance. Reconcile V1 decisions with
[the simplification tracker](https://github.com/shakacode/agent-workflows/issues/822)
and [the product reset](https://github.com/shakacode/agent-workflows/issues/850).
Do not create another migration tracker or require the V1 backlog to be cleared.

| Order | User outcome | Evidence before moving on |
| --- | --- | --- |
| 1 | Simple startup: model/low-effort recommendation, existing seam reuse or minimal setup offer, scoped Ask/Auto choice, useful task names. | Maintainer runs the getting-started manual prompts in fresh tasks, with existing and missing seams. Actual host settings and missing capabilities are visible. |
| 2 | Reliably finish ordinary work across different repositories. | Finish the existing pilots, including UI evidence, review recovery and each consumer's native merge requirements. Compare developer interventions and total available usage for like work; no savings claim while attribution is incomplete. |
| 3 | Make V2 the ordinary workflow and retain only valuable gaps. | Switch consumers individually, document rollback and remaining limitations, then update installation/docs to make V2 the default. Keep V1 available until affected consumers have a working replacement. |

The initial feature disposition below is a recommendation, not an exhaustive
inventory or permission to close V1 items. For the broader inventory, group existing
skills, open PRs and issues by user outcome. For each group record its source link,
current V2 equivalent, observed missing behavior, priority, and acceptance in this
plan. Use **keep, simplify, defer, or retire**; port behavior rather than machinery.

| Feature group | Problem and smallest useful solution | Apparent complexity: build / recurring | Decision and evidence to revisit it |
| --- | --- | --- | --- |
| Seam, authority, current-head checks, trust | Prevent wrong commands or unsafe/out-of-scope actions using the existing seam and native gates. | L–M / L; a replacement policy engine would be H / H. | Keep invariants, simplify mechanisms. Resolve demonstrated consumer failures before adoption. |
| Tests, visual evidence, review, walkthroughs, usage | Make correctness and cost assessable using existing tools and one useful current explanation. | M / M, conditional on the change. | Keep; avoid additional universal audits. Simplify duplicated artifacts or checks while retaining required evidence. |
| Model/effort recommendation and solo default | Avoid paying for expensive reasoning or delegation on bounded work; recommend low effort and verify the actual host setting. | L / L; an automatic model-routing service would be H / UNKNOWN until scoped. | Keep the short recommendation. Escalate from observed difficulty; compare total retry/review cost before claiming savings. |
| Searchable task names | Help a maintainer find the right task. Use native rename with repository, verified issue/PR and outcome; preserve user titles. | L / L. | Simplify [V1 PR #841](https://github.com/shakacode/agent-workflows/pull/841). Verify naming/update in the manual trial; no title schema, synchronization or coordination dependency. |
| Planning and resume | Avoid repeating exploration or losing unfinished work. Use an optional short handoff and one owner with preserved evidence. | L / L when needed; M recurring for mandatory handoffs. | Simplify. Fresh tasks for new objectives; reuse the current task for ongoing ownership. Defer a separate planning skill until existing `$sw` planning repeatedly fails a concrete need. |
| Claude Code/Cursor delivery | Users need the same ordinary outcome in their chosen host. Validate the portable skill and each host’s real boundaries. | M–H / M across hosts; unknown usage fields remain UNKNOWN. | Follow the already-approved Claude Code, then Cursor validation sequence. Verify a complete delivery path before claiming parity; do not burden ordinary Codex tasks with compatibility work. |
| Documentation website | Users cannot find a clear install-to-first-PR path. Publish the existing concise guides on the established site. | M / L with reused content; M recurring if maintaining duplicate manuals. | Keep the staged website plan. Verify a first-time user can finish setup; avoid another content platform or copied source of truth. |
| Fleet coordination, native stacks, autonomous merge control plane | Concurrent/dependent work can need coordination beyond one owner. Start with GitHub issues/PRs and sequential delivery. | H / H for a control plane; native stack integration still needs a bounded design. | Defer behind an explicit advanced boundary. Reconsider only after a real concurrent-writer/dependency case defeats the simpler path. Ordinary authorized auto-merge remains in the kernel. |

Retiring V1 means ending its use for replaced workflows. Archiving its repository,
closing issues/PRs, removing other users' installations, and retiring unreplaced
release/domain workflows require separate explicit decisions. Comparative savings,
complete feature coverage, and the final retirement date remain UNKNOWN.

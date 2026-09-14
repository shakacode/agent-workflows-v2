# Agent Workflows V2

A small, portable workflow for one agent and one pull request. Public pilot.

Give the agent a task or PR link. It implements the change, runs the repository's
checks, explains the code on the PR, handles review, and reaches your requested
stopping point. GitHub holds the PR state; no coordination service is needed.

After installation, start from your repository:

```bash
aw work "Fix the failing search test"
```

Or give it a task URL. The launcher opens native interactive Codex, identifies the
checkout, and supplies the trusted workflow. Codex keeps your account and model
settings; the agent asks about merging when your instructions have not settled it.

The goal is better results with less developer time, fewer tokens, and shorter
delivery time. Clear communication is part of that: see what changed, what matters,
and whether the agent needs a decision. Supporting evidence stays available in
expandable details.

**[Start here: install and fix your first issue or Linear task](docs/getting-started.md).**

Behavior changes follow test-driven development: reproduce the failure, make the
test pass, then refactor. Visible changes include inspected screenshots, with short
video when interaction matters. See [tests and visual evidence](docs/verification.md).

## Two merge preferences

- **Ask:** publish the walkthrough, wait for required checks/review, then request
  one merge decision.
- **Auto:** publish the same walkthrough and merge when required gates pass and
  the task authorizes automatic merging. Required GitHub approval remains a gate,
  not a second question after the reviewer approves.

A request to review or publish a PR without merging is task scope. Both merge
preferences respect it. Consequential risk or uncertain authority requires a
human decision. A short diff alone does not make a change safe to auto-merge.

With **Auto**, the agent merges the version it verified while your task is active.
If a check fails or a decision is needed, it explains what is blocking progress.
Once the task ends, resume it to continue; no merge is left scheduled in the background.

<details>
<summary>Current merge requirements and limits</summary>

GitHub must require checks and enforce them for the account doing the merge.
If the helper cannot verify those requirements, or the account can bypass them,
it stops and explains why. New commits need fresh verification before merging.
The pilot does not support GitHub merge queues yet.

</details>

## Working with your agent

The agent asks about unclear goals before work and raises consequential discoveries
when they arise during implementation. It recommends an answer and explains the
tradeoff. Routine, reversible choices stay with the agent; questions do not wait
for a finished PR or become a mandatory interview.

Updates lead with progress, a blocker, or a decision you need to make. The final
message gives the outcome and PR link. Detailed checks and model/token records
belong in expandable PR details; risks and required decisions remain visible.
See [working with your agent](docs/working-with-your-agent.md) for examples.

Every task reports available model, reasoning-setting, and token evidence, with
shared work and missing data labeled. The agent runs the native Codex
[usage reader](docs/usage-reporting.md); unavailable fields stay UNKNOWN. The
[pilot plan](docs/pilot-plan.md#success-evidence-and-commit-attribution) defines
the evidence needed before claiming savings. Writing preferences belong in your
repo's existing `AGENTS.md`; see [communication and safety](docs/working-with-your-agent.md).

## Each repository keeps its seam

The shared skill supplies the workflow; your repository supplies its commands and
policy. It reads `AGENTS.md` and the files that document points to. Existing
`.agents/bin/` commands and `.agents/agent-workflow.yml` stay in place. Repos that
declare commands directly in `AGENTS.md` can keep doing so.

The seam supplies setup, validation, focused checks, base branch, review and
changelog/release conventions, and merge authority. A Ruby repo, a Rails/React
app, and an Astro site can share the skill while keeping their own commands.
The pilot's `bin/validate` is its own development command, not a consumer default.
GitHub still enforces required checks and approvals. V1 coordination and automation
settings do not activate those features in V2; full V1 policy compatibility is not
claimed. See the [seam boundary](docs/pilot-plan.md#repository-seam).

## Host support

Codex is the first reference host. Keep one shared skill and GitHub workflow;
validate Claude Code next, then Cursor, before claiming full support for them.
Both are compatibility targets today. The Codex usage reader names its tested
record formats and reports gaps; Claude and Cursor reporting remain unverified.
See [tested host support](docs/host-support.md) and the
[host boundary](docs/pilot-plan.md#host-boundary)
for the rollout and the differences that affect model and token reporting.

## Install and use

Follow the [getting-started guide](docs/getting-started.md) for prerequisites,
copyable install commands, a GitHub issue or Linear task, upgrades, and removal.
It installs into a dedicated pilot directory and invokes the trusted skill by path;
each repository keeps its own policy. Your global agent profile is unchanged.
The helpers protect GitHub operations and merge requirements; your agent's
permissions protect execution and credentials. The same baseline applies to
public and private repos. See [what the helpers protect](docs/working-with-your-agent.md#what-the-helpers-protect).

## Develop

```bash
bundle install
bin/validate
```

Tests cover command behavior and failures; RuboCop uses ordinary production
complexity limits. Executable logic lives in Ruby, not Markdown instructions.
The root [Gemfile](Gemfile) and lockfile manage development dependencies; runtime
helpers use Ruby's standard library. A local prerelease gem packages the same skill
and helpers; see [build and test the gem](docs/packaging.md). Registry publication
and the license decision remain outstanding.
The [packaging plan](docs/pilot-plan.md#ruby-packaging) describes the path to one.
See [the pilot plan](docs/pilot-plan.md) for requirements, acceptance cases,
rollout, and current scope. [Issue #1](https://github.com/shakacode/agent-workflows-v2/issues/1)
owns the pilot. No release or adoption claim follows from tests alone.

The planned V2 guide will live on [agents.shakacode.com](https://agents.shakacode.com),
which currently documents V1. See the [website plan](docs/pilot-plan.md#documentation-website)
for the transition and ShakaStack documentation conventions.

# Agent Workflows V2

A small, portable workflow for one agent and one pull request. Public pilot.

Give the agent a task or PR link. It implements the change, runs the repository's
checks, explains the code on the PR, handles review, and reaches your requested
stopping point. GitHub holds the PR state; no coordination service is needed.

The goal is better results with less developer time, fewer tokens, and shorter
delivery time. Clear communication is part of that: see what changed, what matters,
and whether the agent needs a decision. Supporting evidence stays available in
expandable details.

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

Per-commit usage reporting is planned: models, reasoning settings, and tokens,
with shared work and missing data labeled. Automatic collection is not implemented
yet; the [pilot plan](docs/pilot-plan.md#success-evidence-and-commit-attribution)
defines the evidence needed before claiming savings.

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
Both are compatibility targets today. Automated usage reporting is not yet
implemented for any host. See the [host boundary](docs/pilot-plan.md#host-boundary)
for the rollout and the differences that affect model and token reporting.

## Try the isolated pilot

Requires Ruby 3.4, Git, an authenticated GitHub CLI, and a trusted checkout of this
repository. Runtime uses the Ruby standard library; Bundler is for development.

```bash
bin/install --skills-dir /absolute/path/to/isolated-profile/skills
```

Use a separate agent profile with V1 workflows and hooks disabled. The installer
creates only a `work-pr-v2` symlink and refuses to overwrite another skill. It
does not edit your active profile or configure authentication.

In a new session using that profile:

```text
Use $work-pr-v2 to implement this task and open a PR. Ask before merging.
```

For an authorized ordinary task, choose “merge when gates pass” instead.
The skill publishes a COMMENT review explaining the change and linking to its
code. That review is useful after merge and does not pretend to be approval.

Upgrade by updating the trusted source checkout with `git pull --ff-only` on its
chosen branch. The symlink continues to use that checkout. Review the update
before starting a new task. To roll back, use the previous trusted revision or
remove the pilot symlink; other skills and V1 remain unchanged.

## Develop

```bash
bundle install
bin/validate
```

Tests cover command behavior and failures; RuboCop uses ordinary production
complexity limits. Executable logic lives in Ruby, not Markdown instructions.
See [the pilot plan](docs/pilot-plan.md) for requirements, acceptance cases,
rollout, and current scope. [Issue #1](https://github.com/shakacode/agent-workflows-v2/issues/1)
owns the pilot. No release or adoption claim follows from tests alone.

The planned V2 guide will live on [agents.shakacode.com](https://agents.shakacode.com),
which currently documents V1. See the [website plan](docs/pilot-plan.md#documentation-website)
for the transition and ShakaStack documentation conventions.

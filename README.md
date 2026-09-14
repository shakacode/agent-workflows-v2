# Agent Workflows V2

A small, portable workflow for one agent and one pull request. Private pilot.

Give the agent a task or PR link. It implements the change, runs the repository's
checks, explains the code on the PR, handles review, and reaches your requested
stopping point. GitHub holds the PR state; no coordination service is needed.

## Two merge preferences

- **Ask:** publish the walkthrough, wait for required checks/review, then request
  one merge decision.
- **Auto:** publish the same walkthrough and merge when required gates pass and
  the task authorizes automatic merging. Required GitHub approval remains a gate,
  not a second question after the reviewer approves.

A request to review or publish a PR without merging is task scope. Both merge
preferences respect it. Consequential risk or uncertain authority requires a
human decision. A short diff alone does not make a change safe to auto-merge.

The pilot uses an immediate expected-head merge. It does not arm delayed native
auto-merge or continue running after the owning task ends. Merge queues are not
supported yet. Native checks must be configured and enforced on the acting user;
missing evidence or bypass capability produces a clear blocker.

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

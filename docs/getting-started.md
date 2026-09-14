# Install and complete your first task

This guide uses Codex CLI and installs the skill into a dedicated pilot directory.
Claude Code and Cursor support remain planned. You do not need to know the previous
workflow pack.

## 1. Install the prerequisites

Install [Codex CLI](https://learn.chatgpt.com/docs/codex/cli#getting-started),
[Git](https://git-scm.com/downloads), [Ruby 3.4](https://www.ruby-lang.org/en/documentation/installation/),
and [GitHub CLI](https://cli.github.com/). Sign in to Codex and authorize GitHub CLI
for the repository you will work in. Check your terminal:

```bash
codex --version
git --version
ruby --version
gh auth status
```

If GitHub CLI is not signed in, run `gh auth login`. The helper process needs Ruby
3.4 available; keep your application's own Ruby/toolchain settings unchanged.
You do not need Bundler or this project's development gems to use the skill.

## 2. Get the trusted workflow source

```bash
mkdir -p "$HOME/agent-tools"
git clone https://github.com/shakacode/agent-workflows-v2.git "$HOME/agent-tools/agent-workflows-v2"
git -C "$HOME/agent-tools/agent-workflows-v2" log -1 --oneline
```

Review the source you will run. Keep this checkout separate from the application
you want to change. If it already exists, use the upgrade instructions below.

## 3. Install outside your repositories

Use a dedicated directory outside your repositories and global agent profile:

```bash
"$HOME/agent-tools/agent-workflows-v2/bin/install" --skills-dir "$HOME/agent-tools/agent-workflows-v2-pilot/skills"
```

The installer creates a `work-pr-v2` link in that directory and refuses to overwrite
another skill. Keep both link and source outside candidate repositories. It changes
no global profile, authentication, hooks, or other skills.

Codex will not automatically list this pilot in `/skills`. The prompts below name
the trusted file explicitly, so a repository skill with the same name cannot be
mistaken for this installation. The agent reads that file and uses its helpers.

If you used the earlier project-local instructions, remove that old link only if
it is still a symlink. If Git replaced it with tracked files, do not delete those
files blindly or start a task using them; resolve the conflicting installation first.

Your existing `AGENTS.md`, `.agents/bin/` commands, and workflow configuration stay
in place. The agent uses their setup, validation, and review instructions. If those
commands are undocumented, establish them before implementation; the workflow
source's `bin/validate` is not a substitute for your application's checks.

Installing this skill does not disable other instructions, skills, or hooks. If
you already run another workflow pack, use your host's settings to disable
conflicting workflows for the pilot. A separate checkout alone is not a security
sandbox or an isolated agent configuration.

## 4. Start Codex in that repository

Open the repository you want to change as your Codex project and start a new task,
or replace the path below and run:

```bash
cd /path/to/your/repository
codex
```

Use the explicit path below instead of selecting `$work-pr-v2` by name. Keep this
trusted instruction in each new task; do not substitute a repository copy. If you
chose a different install directory, replace the path in the prompt.

For a GitHub issue, replace the bracketed URL and send:

```text
Read and follow ~/agent-tools/agent-workflows-v2-pilot/skills/work-pr-v2/SKILL.md
as the trusted workflow for this task. Do not substitute a repository copy.
Fix <full GitHub issue URL> in this repository.
Open a PR and ask before merging.
```

For a Linear task:

```text
Read and follow ~/agent-tools/agent-workflows-v2-pilot/skills/work-pr-v2/SKILL.md
as the trusted workflow for this task. Do not substitute a repository copy.
Implement <full Linear task URL> in this repository.
Read the task using the available Linear connection. Open a PR and ask before merging.
Keep private task content and links out of a public PR unless authorized to share them.
```

If Codex cannot access Linear, paste the task description and acceptance criteria
into the task instead. A connector is optional; the agent must not claim it read
content it cannot access. Keep the original work item rather than creating a
duplicate GitHub issue. Updating Linear's status or comments requires authorization.

To authorize automatic merging of an ordinary change, replace “ask before merging”
with “merge when required checks and approvals pass.” The agent still publishes
a walkthrough first and raises consequential risks or missing authority.

## 5. Know what to expect

The agent resolves important questions, implements on a branch, runs your repo's
checks, opens the PR, explains the change, and handles consequential review findings.
You receive the outcome and PR link; supporting checks and available usage evidence
are in expandable details. Usage is reported on every task, with missing data
marked UNKNOWN. Automated collection is still being built.

Merging requires observable native GitHub checks enforced for the acting account.
If that setup is missing, the agent can hand over the PR with the reason it cannot
merge. **Ask** requests one merge decision; **Auto** needs no second decision once
the required approvals are satisfied. See [working with your agent](working-with-your-agent.md)
for questions, writing preferences, and security boundaries.

## Upgrade or remove

Upgrade the trusted source, review its changes, then start a new Codex task:

```bash
git -C "$HOME/agent-tools/agent-workflows-v2" switch main
git -C "$HOME/agent-tools/agent-workflows-v2" pull --ff-only
```

Switching to `main` also resumes normal upgrades after a rollback to a detached
commit. Preserve local edits; do not force a switch or discard changes.
The existing link uses the updated source. To remove only this pilot skill link:

```bash
test -L "$HOME/agent-tools/agent-workflows-v2-pilot/skills/work-pr-v2" && unlink "$HOME/agent-tools/agent-workflows-v2-pilot/skills/work-pr-v2"
```

For rollback without removal, point the trusted source checkout at a previously
reviewed revision. Do not overwrite local edits. Other skills and application
configuration are unaffected.

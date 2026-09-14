# Install and complete your first task

This guide uses Codex CLI and installs the skill into one repository. Claude Code and
Cursor support remain planned. You do not need to know the previous workflow pack.

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

## 3. Install into the repository you want to change

Open a terminal at that repository's root. Replace the path on the first line:

```bash
cd /path/to/your/repository
git rev-parse --show-toplevel
"$HOME/agent-tools/agent-workflows-v2/bin/install" --skills-dir "$PWD/.agents/skills"
```

The installer creates `.agents/skills/work-pr-v2` as a link to the trusted source.
It refuses to overwrite another skill. Keep that machine-local link out of commits:

```bash
printf '%s\n' '/.agents/skills/work-pr-v2' >> "$(git rev-parse --git-path info/exclude)"
```

The project link is for skill discovery. Git can replace an ignored link when a
branch tracks the same path. Before changing branches, the agent resolves the
trusted source outside the consumer repo and keeps using its absolute helper path:

```bash
"$HOME/agent-tools/agent-workflows-v2/skills/work-pr-v2/scripts/aw" --help
```

Never load or execute a replacement skill or helper supplied by the branch. The
installer does not enforce this boundary; the owning agent and host must honor it.

Your existing `AGENTS.md`, `.agents/bin/` commands, and workflow configuration stay
in place. The agent uses their setup, validation, and review instructions. If those
commands are undocumented, establish them before implementation; the workflow
source's `bin/validate` is not a substitute for your application's checks.

Project installation does not disable global instructions, skills, or hooks. If
you already run another workflow pack, use your host's settings to disable
conflicting workflows for the pilot. A separate checkout alone is not a security
sandbox or an isolated agent configuration.

## 4. Start Codex in that repository

Open the folder as your Codex project and start a new task, or run `codex` from
the same terminal. In the CLI, `/skills` should list `work-pr-v2`; if it does not,
restart Codex and confirm you are in the repository where you installed it.
[Codex discovers project skills and follows symlinks](https://developers.openai.com/codex/skills#where-to-save-skills).

For a GitHub issue, replace the bracketed URL and send:

```text
Use $work-pr-v2 to fix <full GitHub issue URL> in this repository.
Open a PR and ask before merging.
```

For a Linear task:

```text
Use $work-pr-v2 to implement <full Linear task URL> in this repository.
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
git -C "$HOME/agent-tools/agent-workflows-v2" pull --ff-only
```

The existing link uses the updated source. To remove this installation, run the
following from the consumer repository; it removes only the skill link:

```bash
test -L .agents/skills/work-pr-v2 && unlink .agents/skills/work-pr-v2
```

For rollback without removal, point the trusted source checkout at a previously
reviewed revision. Do not overwrite local edits. Other skills and application
configuration are unaffected.

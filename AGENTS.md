# Agent Workflows V2

This private pilot implements the small product described in `docs/pilot-plan.md`.
The maintainer authorized implementation, publication, and merging verified PRs.
Keep company strategy and private operational data out of product artifacts.

## Working agreement

- One root task owns integration, publication, and user communication. Use bounded
  subagents only when authorized. Give each implementation worker exclusive files
  or an isolated worktree; workers do not publish or merge.
- This is a fresh kernel. Do not import V1 workflow contracts, ledgers, schemas,
  review reducers, coordination clients, or policy engines as dependencies.
- GitHub issue #1 owns this pilot. Keep the implementation to its requirements.
  Use `jg-codex/1-<description>` branches and PRs; never push to `main`.
- Product merge preferences are `ask` and `auto`. Review-only work stops at its
  requested outcome. Existing maintainer merge authority persists; do not ask again.
- Preserve user changes. Pull/rebase before edits when a branch has an upstream;
  for a new branch start from the freshly fetched base. Do not reset others' work.

## Structure

- `docs/pilot-plan.md` owns product requirements, design, acceptance, and scope.
- `skills/work-pr-v2/SKILL.md` is the portable, self-contained entry point.
- Its `scripts/aw` command uses small Ruby modules under its `lib/` directory.
- `bin/install` links only this skill into an explicitly supplied skills directory.
- Markdown explains decisions and invokes commands. Put executable logic in code.
- Prefer Ruby standard libraries and GitHub CLI. Runtime needs no new gem.
- Tests verify behavior and failures, not exact instruction wording. Keep focused
  files and use normal RuboCop defaults; no baseline ratchet or global metrics disable.

## Agent Workflow Configuration

Base branch: `main`. Plan location: `docs/pilot-plan.md`.
Validation: `bin/validate` runs tests and `bundle exec rubocop`.
Dependencies: `bundle install`. Ruby: 3.4 for the initial pilot.
Review: one visible independent review of meaningful implementation changes.
Coordination: none; this controlled pilot has no independent same-target writer.
Merge authority: auto for this pilot's reviewed, verified implementation PRs.
Release: private pilot, no public release, registry publication, or global install.

## Completion

Publish tested changes as bounded PRs, preferably below 500 changed lines each.
Explain necessary larger changes; split independent work instead of hiding size.
Required evidence is the PR's current commit, actual validation results, and review.
No extra closeout audit, receipt, automatic issue, heartbeat, or parallel tracker.
Report available model, reasoning effort, and token evidence on the PR by commit;
mark shared or unavailable attribution explicitly, as specified in the pilot plan.
Do not close the pilot until its required real-use acceptance is established.

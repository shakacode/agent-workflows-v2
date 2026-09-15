---
name: shaka-learn
description: Improve Shaka from observed delivery failures, compare model and effort costs, and run its project-local supervisor trial. Use for Shaka maintenance and evaluation, not ordinary consumer PRs.
---

# Shaka repair and learning

Use one supervisor as the maintainer's contact for Shaka development. This internal
skill is a candidate for review; it does not alter the installed public skill or
authorize new workers, external messages, merges, or background monitoring.
Read the [trial and cost guide](references/repair-and-learning.md) when planning
an experiment or acting as the appointed supervisor. Keep outcomes on the existing
issue/PR; #1 owns acceptance and #36 owns scope. Do not create another tracker.

## Repair a demonstrated failure

1. Link the observed result and expected behavior. Reproduce the miss. Separate
   faulty requirements, instruction ambiguity, tool/serialization failure, missing
   evidence, and model reasoning failure before choosing a remedy.
2. Prefer deterministic Ruby for repeated mechanics and a shorter instruction
   for a decision. Preserve current-head checks, trust boundaries, merge authority
   and required review. Do not encode every reviewer suggestion as a new rule.
3. Gather findings for the same head into one repair batch; recheck affected
   behavior, then the required gate. After two unsuccessful repair rounds on the
   same failure family, reconsider the design or scope. This is no permission to
   waive a failing gate. Fix formatting without a model turn where possible.
4. Replay the original miss and an unaffected case. For skill decisions, use
   observable task actions and published artifacts; wording/size tests and an
   agent saying it complied do not establish behavior. Mark simulations as such.
5. Try a few comparable real tasks with recorded skill revision, model AND effort.
   Count supervision, review, repairs and human rescue. Keep, revise or revert
   based on accepted correctness and total cost/attention/time; delete unsuccessful
   added rules. Significant lessons go on the existing work item.

## Supervise authorized workers

Give each worker one bounded outcome, acceptance evidence, isolated checkout or
exclusive files, model/effort, repair limit and stopping point. Reuse existing
tasks; do not start another writer on an owned branch. Preserve explicit user
settings, scope and authority. Change actual host settings only within delegated
authority; an instruction cannot change them. If unsupported, surface one action.

Read compact task status and live PR evidence at meaningful changes. Workers
implement and test; the supervisor verifies acceptance and final publication.
Do not treat a worker's success claim or a green review job as proof. Reuse required
independent review; supervision neither substitutes for it nor adds another human
approval. Consolidate corrections into one message. Keep the maintainer's updates
to outcomes, blockers and decisions with a recommendation.

Start ordinary worker trials at Terra/low unless instructed otherwise. Compare
Terra/medium on matched work before assuming a different model is needed. Escalate
for demonstrated reasoning difficulty or consequential risk, never for malformed
Markdown, CI waiting or API failures. Keep the user's Astra/xhigh review of #38
separate from ordinary-task comparisons. No recursive supervisors or automatic
follow-up issues; no recurring monitoring unless explicitly requested.

Price disjoint token categories using the applicable sourced rates, recording
billing mode, model, effort, interval and coverage. Keep estimates separate from
actual charges. UNKNOWN is not zero; count shared responses once, including
supervisor/reviewer work. Publish aggregate evidence, not private session contents.

<!--
WHAT: The milestones, their order and what each one delivers.
READERS: The owner, agents choosing the next task, anyone asking "what comes next".
UPDATE: When a milestone starts, finishes, splits or is reordered. Task detail lives in the plan files, not here.
No UI (backend-only)? Delete the UI lines: the design system and first-slice wording in M1 and any device check of screens.
-->

# Roadmap

Work is identified by milestone task ids such as `{{TASK_ID_EXAMPLE}}`. Plans live in {{PLAN_LOCATION}}. <!-- PLAN_LOCATION: folder holding the milestone plans, e.g. docs/plans/ -->

## Milestones

| Id | Name | Delivers | Status |
|---|---|---|---|
| M0 | Foundation | repo layout, verify script, CI, docs set, security baseline | {{STATUS}} |
| M1 | Design system and first slice | tokens, kit, languages, one vertical slice on a real device | {{STATUS}} |
| M2 | {{NAME}} | {{DELIVERABLE}} | {{STATUS}} |
| M3 | {{NAME}} | {{DELIVERABLE}} | {{STATUS}} |
| M{{N}} | First release | store or deploy, release docs, changelog | {{STATUS}} |

Status values: planned, in progress, in review, done.

## Order and dependencies

- {{MILESTONE}} needs {{MILESTONE}} because {{REASON}}.
- Nothing ships before the gate is green and a device check is reported.

## Current focus

{{MILESTONE_AND_GOAL}}. Next after it: {{MILESTONE}}.

## Later

Ideas not yet scheduled. Nothing here is built until it becomes a milestone task and the owner agrees.

- {{IDEA}}

## Out of scope

- {{THING_WE_WILL_NOT_BUILD_AND_WHY}}

## How a milestone is closed

1. Every task done with its tests.
2. Verify green; device check reported honestly.
3. `HANDOFF.md`, `SUMMARY.md` and `CHANGELOG.md` updated.
4. The owner merges.

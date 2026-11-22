<!--
WHAT: Where work stands right now, so the next session or person continues without re-deriving it.
READERS: The next agent or developer picking up the work.
UPDATE: At the end of every working session and before any context reset. Overwrite stale lines; do not let it grow into a diary.
-->

# Handoff

Last updated: {{DATE}} by {{AUTHOR_ROLE}}.

## Current task

- Task: `{{TASK_ID}}`, {{ONE_LINE_GOAL}}.
- Branch: `{{BRANCH}}`. Pull request: {{PR_OR_NONE}}.
- State: {{STATUS}}<!-- STATUS: not started, in progress, in review or blocked -->.

## Done so far

- {{FINISHED_ITEM_WITH_TASK_ID}}
- {{FINISHED_ITEM_WITH_TASK_ID}}

## Next steps

1. {{NEXT_STEP}}<!-- NEXT_STEP: concrete enough to start without asking -->
2. {{NEXT_STEP}}
3. {{NEXT_STEP}}

## Open questions for the owner

- {{QUESTION}} (blocks: {{WHAT}})

Ambiguity goes here, never guessed.

## Decisions made this session

- {{DECISION}}, recorded as D{{N}} in `decisions.md`.

## Checks

| Check | Result |
|---|---|
| `{{VERIFY_COMMAND}}` | {{PASS_FAIL_AND_DATE}} |
| Architecture tests | {{RESULT}} |

## Not verified

Say plainly what was not checked.

- On a device or browser: {{NOT_DONE}}
- Languages and themes not looked at: {{LIST}}
- Right-to-left, reduce-motion, width classes not checked: {{LIST}}
- Against the real dev backend: {{DONE_OR_NOT}}

## Known problems

- {{PROBLEM}}: {{WHERE}}, planned fix in {{TASK_ID}}. Every found bug gets a tested fix in a named task.

## Files and areas touched

- {{PATH}}: {{WHY}}

## How to resume

```bash
{{RESUME_COMMANDS}}<!-- RESUME_COMMANDS: e.g. git checkout, install, verify -->
```

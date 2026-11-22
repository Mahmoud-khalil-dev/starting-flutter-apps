<!--
WHAT: How to propose a change and get it landed.
READERS: Anyone opening a pull request, human or agent.
UPDATE: When the branch model, review rules or checks change. Keep it short; details live in docs/WORKFLOW.md.
-->

# Contributing

Read `AGENTS.md` first; its rules apply to everyone. Branches, commits, review and release are in `docs/WORKFLOW.md`.

## Before you start

1. Pick a task from {{PLAN_LOCATION}}. Build only what a task names; anything else goes to the owner first. <!-- PLAN_LOCATION: folder holding the milestone plans, e.g. docs/plans/ -->
2. Branch from {{INTEGRATION_BRANCH}} using `{{BRANCH_NAME_PATTERN}}`. <!-- BRANCH_NAME_PATTERN: e.g. feat/<task-id>-<slug> -->
3. Read the area's section in `docs/GOTCHAS.md` when it exists.

## Making the change

1. Write a failing test first, with the task id in its name.
2. Write the least code that passes.
3. Add strings for every language in the same change; never hand-edit generated files.
4. Run the gate:

```bash
{{VERIFY_COMMAND}}
```

5. For UI, run the app and look at it in each language, theme and width class.

## Commits

Conventional Commits with the task id as scope, imperative, at most 72 characters: `{{COMMIT_EXAMPLE}}`. Keep one logical change per commit.

## Pull requests

- Title carries the task id. Target {{INTEGRATION_BRANCH}}.
- Description: what changed, why, the tests added, what you checked on a device and what you did not.
- No secrets, no real env files, no seed, demo or fake data (decision D3; test doubles live in tests only).
- The owner reviews and merges. Do not merge your own pull request or push to a protected branch.

## Review checklist

- [ ] Failing test first, named with the task id
- [ ] Verify command passes
- [ ] No rule exemption for a single file
- [ ] Both directions and both themes looked at, reduce-motion respected
- [ ] Docs updated where the change touches them
- [ ] Changelog line added if user-visible

## Reporting problems

Bugs: open an issue with steps, expected and actual result. Security: see `SECURITY.md`.

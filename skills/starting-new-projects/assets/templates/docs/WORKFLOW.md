<!--
WHAT: Branches, commits, review and release: how a change travels from idea to users.
READERS: Everyone who opens a branch, a pull request or a release.
UPDATE: When the branch model, protections, versioning or review steps change.
-->

# Workflow

## Roles in the flow

- **Developers and agents** branch, commit and open pull requests.
- **The owner reviews, merges and pushes.** No agent merges, pushes to a protected branch or force-pushes.
- Pull requests use {{PR_TEMPLATE_PATH}}; reviewers per path are in {{CODEOWNERS_PATH}}. <!-- PR_TEMPLATE_PATH: the pull request template file --> <!-- CODEOWNERS_PATH: the file mapping paths to reviewers -->

## Branches

| Branch | Purpose | Who writes |
|---|---|---|
| {{PROTECTED_MAIN}} | what users run; protected | owner only |
| {{INTEGRATION_BRANCH}} | integration of finished work | pull requests, owner merges |
| `{{BRANCH_NAME_PATTERN}}` | one task or milestone | its author |

Pull requests target {{INTEGRATION_BRANCH}} until {{NEXT_RELEASE}} ships, then {{DEFAULT_BRANCH_AFTER}}.

## Commits

- Conventional Commits, task id as scope, imperative, at most 72 characters: `{{COMMIT_EXAMPLE}}`.
- Types: feat, fix, docs, test, refactor, chore, build, ci.
- One logical change per commit; never commit a secret or a real env file.

## A change, step by step

1. Pick a task; branch from {{INTEGRATION_BRANCH}}.
2. Failing test, least code, repeat.
3. Run `{{VERIFY_COMMAND}}`; fix the cause, never weaken a check.
4. Look at the result on a device or browser in each language and theme.
5. Open a pull request with the task id in the title.
6. The owner reviews; address comments with new commits.
7. The owner merges.

## Review

Reviewer checks: test failed first, gate green, no per-file exemption, no fake data shipped (decision D3; tests hold the doubles), both directions and themes, docs and changelog updated, honest "done" statement in the description.

## Versioning and changelog

- Scheme: {{VERSIONING_SCHEME}}. The version lives in {{VERSION_FILE}}; a drift check compares generated copies.
- User-visible changes get a line under Unreleased in `CHANGELOG.md`.

## Release

Build, sign and ship steps are in `BUILD_AND_RELEASE.md` once it exists. Release builds use the production config; nothing else does. After the first release, follow the `releasing-live-app-updates` skill for updates to a live product.

## Hotfixes

{{HOTFIX_PATH}}<!-- HOTFIX_PATH: branch from the released tag, same gate, owner merges, then merge back -->.

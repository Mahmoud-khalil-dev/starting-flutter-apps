---
name: starting-new-projects
description: Use when starting a new app, repo, service or product, or when someone says "set up a new project", "scaffold a new project", "project structure", "what docs do we need", or asks for an AGENTS.md or CLAUDE.md for a new repo, or when a young repo has no agent rules, no verify script or no docs yet.
---

# Starting New Projects

## Overview

A rule that no check enforces drifts, and drift is cheapest to stop on day 0.

**Core rule: a code rule is not a rule until a script fails when it is broken.** Write the rule, the check, and the doc that names both. A process rule (owner merges, honest "done", ask when unsure) is backed by branch protection, a required check, a commit-message check or a named review-checklist item.

## When to use

- A new app, repo, service or product, mobile, web or backend.
- A young repo with no agent rules, verify command or docs.

Not for: a product users already run (use `releasing-live-app-updates`). A live repo with no agent rules or docs: use these templates; that skill's contract rules govern any code change.

## Day-0 sequence, in order

1. **Frame the product.** Users, roles, platforms, languages (RTL and digits included). Optional skills that help each step: `references/skills-to-use.md` (none required).
2. **Start a decisions log.** One numbered line per owner decision, with date and reason.
3. **Lay out the repo by feature.** One folder per feature, shared code apart. **Flutter:** run `scripts/new-flutter-app "<App Name>"`, fill `brand.dart`, read `references/flutter-kit.md`.
4. **Config per environment.** Committed example files, git-ignored real ones, one `Env` reader. No host or key in source. Keep the API contract (schema or OpenAPI file) in `contracts/`; generate clients from it or test against it.
5. **One verify script.** One command, same locally and in CI; steps in the reference, section 9.
6. **Security baseline, starting with the secret scan.** Secrets handling, private reporting route, dependency audit, least-privilege tokens.
7. **CI runs that script as a required check;** branch protection blocks merge on red.
8. **Agent rules file and the docs set.** Copy from the templates per the Write column below; fill every placeholder. Add a PR template and CODEOWNERS. Stub later docs or leave them off the read list.
9. **Design tokens, i18n/RTL and accessibility in the first screen.** Calm motion with a reduced-motion version; retrofitting touches every file.
10. **A platform capabilities object.** Screens ask what the platform can do.
11. **Observability and privacy.** Crash reporting, an analytics event-name registry file with a test, like the key registry, and session-recording masking.
12. **First vertical slice, end to end, on a real device.** One test per layer.
13. **Branching and release flow.** Who merges, what is protected, how versions move. The owner merges, pushes, deploys and submits; never commit secrets; production is never a test bed.

## The docs set

| File | Purpose | Template | Write |
|---|---|---|---|
| `AGENTS.md` | Rules for agents and humans | `assets/templates/AGENTS.md` | Day 0 |
| `CLAUDE.md` | One-line import of `AGENTS.md` | `assets/templates/CLAUDE.md` | Day 0 |
| `README.md` | What, how to run | `assets/templates/README.md` | Day 0 |
| `SECURITY.md` | Secrets, reporting | `assets/templates/SECURITY.md` | Day 0 |
| `CONTRIBUTING.md` | How to propose and land a change | `assets/templates/CONTRIBUTING.md` | Day 0 |
| `CHANGELOG.md` | What changed per version | `assets/templates/CHANGELOG.md` | First release |
| `docs/SUMMARY.md` | App, roles, state | `assets/templates/docs/SUMMARY.md` | Day 0 |
| `docs/ROLES.md` | What each role can do | `assets/templates/docs/ROLES.md` | Day 0 |
| `docs/ARCHITECTURE.md` | Structure and enforced rules | `assets/templates/docs/ARCHITECTURE.md` | Day 0 |
| `docs/DEVELOPER_GUIDE.md` | Playbook per addition | `assets/templates/docs/DEVELOPER_GUIDE.md` | First feature |
| `docs/WORKFLOW.md` | Branches, commits, review, release | `assets/templates/docs/WORKFLOW.md` | Day 0 |
| `docs/GOTCHAS.md` | Traps and fixes | `assets/templates/docs/GOTCHAS.md` | First feature |
| `docs/HANDOFF.md` | Where work stands, next step | `assets/templates/docs/HANDOFF.md` | First feature |
| `docs/DESIGN.md` | Tokens, motion, copy, accessibility | `assets/templates/docs/DESIGN.md` | Day 0 |
| `docs/BUILD_AND_RELEASE.md` | Build, sign, ship | `assets/templates/docs/BUILD_AND_RELEASE.md` | First release |
| `docs/TROUBLESHOOTING.md` | Symptom, cause, fix | `assets/templates/docs/TROUBLESHOOTING.md` | First feature |
| `docs/ROADMAP.md` | Milestones and their order | `assets/templates/docs/ROADMAP.md` | Day 0 |
| `docs/decisions.md` | Numbered owner decisions | `assets/templates/docs/decisions.md` | Day 0 |

Backend-only: skip `docs/DESIGN.md` and the UI rules (reference section 7, width classes, RTL lines in `AGENTS.md`).

## Where to look

- `references/structure-and-rules.md`: layout and rules.
- `references/skills-to-use.md`: optional companion skills per step; none are required.
- `references/flutter-kit.md`: Flutter kit modules and day-0 order.
- `assets/templates/`: copy, fill every placeholder, delete the guidance comments.


## Common mistakes

| Mistake | Fix |
|---|---|
| Prose rule, no check | Code rule: add the check to the verify script or drop it. Process rule: back it with a platform setting or checklist item. |
| Placeholders left in | Grep for `{{` before committing. |
| Docs never updated | Headers say when to update. |
| Real env file or key committed "temporarily" | Commit examples only; scan in CI. |
| RTL, languages and accessibility "later" | Do them in the first screen. |
| Fake data to unblock the UI | Real dev backend once it exists; before that only a stub built from the API contract (decision D3 in `assets/templates/docs/decisions.md`: dev-only path, import-banned, refused by release start-up). Doubles live in tests. Nothing fake ships. |
| Framework layout, no dependency rules | Write import rules; test them. |

## Red flags: stop and fix the base

- No single command proves the gate.
- A host or key appears in source, or an id lives outside its registry or config file.
- The agent rules file exists but no check backs a single rule in it.
- Tests pass and "done" is claimed with no device check.
- Code lands before its failing test.

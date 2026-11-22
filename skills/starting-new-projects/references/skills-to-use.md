# Skills to use while starting a project

Contents:
1. Gate for outside skills; 2. Day-0 steps; 3. Later phases
4. Stack-specific skills; 5. After large changes; Rules

**All of these are optional.** Every step in `SKILL.md` works with no other skill installed. The skills below only make a step stronger; skip any you do not have.

## Start here: the five most useful

| Skill | Helps with | Where to get it |
|---|---|---|
| `superpowers:brainstorming` | Step 1, framing the product | [obra/superpowers](https://github.com/obra/superpowers) |
| `superpowers:test-driven-development` | Steps 5 and 12, test-first | same plugin |
| `superpowers:systematic-debugging` | any failing gate | same plugin |
| `superpowers:verification-before-completion` | before saying "done" | same plugin |
| `skill-creator` | changing this skill | [anthropics/skills](https://github.com/anthropics/skills) |

The rest of this file maps more skills to each step, for setups that have them.

Read this at day 0 and whenever a new phase starts. Load each skill with the Skill tool when its work comes up. Skill text does not survive compaction, so reload it after one. If a named skill is not installed, use the closest installed one and say so in the hand-off. Names are exact: user skills by bare name, plugin skills as `superpowers:<name>`.

## 1. Gate for outside skills

- `skill-inspector`: run before installing, updating or recommending any skill, plugin or MCP server from outside. Why: a skill runs with the agent's permissions. Install only on its approve verdict; on caution or reject, stop and ask the owner.
- `find-skills`: when no installed skill fits a need. Pass whatever it finds through `skill-inspector` first.

## 2. Day-0 steps

Step numbers match the day-0 sequence in `SKILL.md`.

1. Frame the product
   - `superpowers:brainstorming`: before any creative work; settles users, roles, platforms and languages.
   - `office-hours`: gstack chain, first choice when the idea is still unproven.
   - `spec`: gstack chain, turns vague intent into a spec.
   - `spec-driven-development`: only when the gstack chain is not in use.
   - `grill-me`: to stress-test a plan that already exists, not to frame one.
   - `domain-modeling`: when the product has several entities and rules to name.
   - `superpowers:writing-plans`: once the scope is agreed; turns it into milestone plans with task ids.
2. Decisions log
   - `documentation-and-adrs`: for the numbered, dated, reasoned decision lines.
3. Repo layout by feature
   - `planning-and-task-breakdown`: when a milestone needs cutting into small tasks.
4. Config per environment
   - `api-and-interface-design`: for the contract file kept in `contracts/` and the module boundaries between features.
   - `find-docs`: for current docs of the stack's config and env tooling, not memory.
5. One verify script
   - `ci-cd-and-automation`: so the same command runs locally and in CI, and as the required check at step 7.
   - `superpowers:test-driven-development`: for the test layers the script runs; also step 12.
6. Security baseline
   - `security-and-hardening`: secrets handling, input trust and dependency audit.
   - `api-security-review`: when the product has an API (also the backend case).
7. CI and branch protection
   - `git-workflow-and-versioning`: branch rules, who merges, commit conventions; also step 13.
8. Agent rules file and docs set
   - `context-engineering`: so the read list gives each session what it needs, no more.
   - `writing-user-docs`: README and user docs only, not the agent rules or developer docs.
9. Design tokens, i18n/RTL, accessibility
   - `frontend-design`: for a distinctive direction before the first screen.
   - `interface-kit`: for tokens, type, color and component craft.
   - `accessible-animation`: so reduced motion is built in with the first motion.
10. Platform capabilities object
   - `responsive-design` covers width classes only; the platform capabilities object has no skill. Follow the reference's rules.
11. Observability and privacy
   - `observability-and-instrumentation`: crash reporting, event registry, masking.
12. First vertical slice
   - Failing test first, one per layer: `superpowers:test-driven-development` (step 5).
   - `incremental-implementation`: to land the slice in thin, verified steps.
   - `superpowers:verification-before-completion`: before saying the slice works.
13. Branching and release flow
   - `shipping-and-launch`: when the first release is near.
   - `setup-deploy`: gstack only; records how deploys are done, for the owner to run.

## 3. Later phases

- **Plan:** `superpowers:writing-plans` for each milestone (see step 1); `autoplan` to run the review pipeline over it; `junior-to-senior` when a plan feels vague or too granular; to frame a feature before its plan, see step 1.
- **Build:** `superpowers:executing-plans` to work a plan with checkpoints; `superpowers:subagent-driven-development` for independent tasks in one session; `superpowers:using-git-worktrees` for an isolated workspace; `superpowers:systematic-debugging` for any bug or failing test before a fix.
- **UI:** `frontend-ui-engineering` for production-quality screens; `researching-ui-components` before redesigning a shared component; `design-motion` and `60fps-animation` for motion (`accessible-animation`: see step 9); `dark-mode-design` when adapting a palette; `copywriting` for marketing pages only, never in-app UI copy.
- **Review:** `superpowers:requesting-code-review` before merge; `superpowers:receiving-code-review` when feedback arrives; `code-review-and-quality` for a diff review; `design-review` for a visual QA pass on a running app in the gstack chain; `web-design-reviewer` to inspect a running site and fix layout and responsive issues in source.
- **Test:** `qa` to test real behavior in a browser; `browse` for any web browsing; `test-audit` to find low-value or duplicate tests; `performance-optimization` and `web-quality-audit` (web: also performance, accessibility, SEO) when quality targets exist.
- **Ship:** `superpowers:finishing-a-development-branch` to choose how the work lands; `ship` to open the pull request (the owner merges); `document-release` to bring docs in line with what shipped; after first release, `releasing-live-app-updates`.

## 4. Stack-specific skills

Load only the ones for the stack in use.

- **Flutter:** `flutter-animations` for implicit and explicit motion, Hero and reduced motion.
- **iOS:** `ios-design-review`, `ios-qa` and `ios-fix` for design checks, testing and fixes on the simulator; `liquid-glass-design` for the newest iOS look.
- **Android:** `artemis-android` to drive a device, only when the owner asks.
- **Web:** `nextjs-app-router-patterns` for routing and server components; `browser-testing-with-devtools` for live inspection; `gsap-timeline` and `gsap-scrolltrigger` for scripted motion.
- **Backend:** the contract and security skills from steps 4 and 6; nothing further.

## 5. After large changes

- `graphify`: build the code graph at the project root once the code is large enough for structural questions; refresh it after a feature lands, a refactor or many moved files. Why: later sessions query the graph instead of re-reading files.
- `context-save` and `context-restore`: to checkpoint and resume work across sessions.

## Rules

- Do not load a skill for work you are not doing; each one costs context.
- A skill's advice never outranks the project's `AGENTS.md`; on a conflict, follow `AGENTS.md` and tell the owner.
- Name the skills used in the hand-off, so the owner sees what shaped the work.

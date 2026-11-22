<!--
WHAT: The product on one page: what it is, who uses it, what exists, where it stands.
READERS: Every agent and teammate, first or second doc read.
UPDATE: At the end of every milestone and whenever the platforms, roles or status change.
-->

# {{PROJECT_NAME}} summary

## What it is

{{TWO_OR_THREE_SENTENCES}}<!-- TWO_OR_THREE_SENTENCES: the product, its audience, the problem it solves -->

## Audience and tone

{{AUDIENCE}}<!-- AUDIENCE: e.g. small-business owners who invoice clients -->. The experience is calm, precise and courteous; nothing loud or playful ships. See `DESIGN.md`.

## Platforms and languages

| Platform | Status | Notes |
|---|---|---|
| {{PLATFORM_A}} | {{STATUS}} | {{CAPABILITY_LIMITS}} |
| {{PLATFORM_B}} | {{STATUS}} | {{CAPABILITY_LIMITS}} |

Languages: {{LANGUAGES}}. Right-to-left: {{RTL_LANGUAGES}}. Numbers display in the locale's digits; the API always gets Western digits.

## Roles

One line per role; the full matrix is in `ROLES.md`.

- **{{ROLE_A}}**: {{WHAT_THEY_DO}}
- **{{ROLE_B}}**: {{WHAT_THEY_DO}}

## Main flows

1. {{FLOW_A}}<!-- FLOW_A: e.g. sign in, then browse, then book -->
2. {{FLOW_B}}

## Systems it talks to

| System | Purpose | Configured by |
|---|---|---|
| {{BACKEND_API}} | {{PURPOSE}} | the `Env` reader; never a literal host |
| {{THIRD_PARTY}} | {{PURPOSE}} | {{WHERE}} |

## Where it stands

- Released version: {{VERSION_OR_NONE}}.
- Current milestone: {{MILESTONE}}; see `ROADMAP.md`.
- Live users: {{YES_OR_NO}}. If yes, persisted keys, channel ids, product ids and event names are public contracts; change them only with a named migration.

## Where to go next

`ARCHITECTURE.md` for structure, `WORKFLOW.md` for how changes land, `decisions.md` for why things are as they are.

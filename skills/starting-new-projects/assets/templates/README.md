<!--
WHAT: The front door: what the product is, how to run it, where the docs are.
READERS: A new teammate or reviewer on their first hour.
UPDATE: When the run steps, requirements, environments or doc map change.
-->

# {{PROJECT_NAME}}

{{ONE_LINE_PITCH}}<!-- ONE_LINE_PITCH: who it is for and what it does, in calm plain words -->

## Status

{{STATUS}}<!-- STATUS: e.g. pre-release, milestone M1 in progress -->. Details: `docs/SUMMARY.md` and `docs/ROADMAP.md`.

## Platforms and languages

- Platforms: {{PLATFORMS}}<!-- PLATFORMS: e.g. phone, tablet, web -->.
- Languages: {{LANGUAGES}}; right-to-left: {{RTL_LANGUAGES}}.

## Requirements

- {{TOOLCHAIN_AND_VERSION}}, pinned in {{VERSION_FILE}}.
- {{OTHER_TOOLS}}<!-- OTHER_TOOLS: e.g. package manager, platform SDKs -->.

## Setup

1. Clone the repo and install dependencies: `{{INSTALL_COMMAND}}`.
2. Copy each example env file to a real one and fill it: `cp {{ENV_EXAMPLE_FILE}} {{ENV_FILE}}`. Real env files are git-ignored. Never commit one. <!-- ENV_EXAMPLE_FILE: its committed example, e.g. env/dev.example.json --> <!-- ENV_FILE: the real, git-ignored env file inside ENV_DIR, e.g. env/dev.json -->
3. Generate code and strings: `{{CODEGEN_COMMAND}}`.

## Run

```bash
{{RUN_COMMAND_DEV}}
```

Run against the dev environment only. The production config is for release builds.

## Check your work

```bash
{{VERIFY_COMMAND}}
```

One command, the same locally and in CI. Passing it is not a device check; see `AGENTS.md`.

## Project layout

{{LAYOUT_SUMMARY}}<!-- LAYOUT_SUMMARY: one short tree, or a pointer to docs/ARCHITECTURE.md -->

## Documentation

| Doc | What it holds |
|---|---|
| `AGENTS.md` | Rules for agents and humans |
| `docs/SUMMARY.md` | The product, roles and current state |
| `docs/ARCHITECTURE.md` | Structure and enforced rules |
| `docs/WORKFLOW.md` | Branches, commits, review, release |
| `docs/DESIGN.md` | Tokens, motion, copy, accessibility |
| `docs/ROADMAP.md` | Milestones |
| `docs/decisions.md` | Owner decisions |

Add later docs (developer guide, gotchas, handoff, build and release, troubleshooting) to this table when they exist.

## Contributing and security

See `CONTRIBUTING.md` and `SECURITY.md`.

## License

{{LICENSE_OR_PROPRIETARY_NOTICE}}

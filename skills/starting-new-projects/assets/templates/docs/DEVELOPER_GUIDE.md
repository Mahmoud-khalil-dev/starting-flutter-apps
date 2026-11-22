<!--
WHAT: A playbook: one short checklist per kind of thing you add.
READERS: Any developer or agent about to add a feature, screen, API call, stored value or string.
UPDATE: When a step, command or path changes; add a playbook when a new kind of work repeats.
-->

# Developer guide

Each playbook is a checklist. Start with a failing test whose name holds the task id.

## Adding a feature

- [ ] Task exists in the plan; note its id.
- [ ] Create `{{SOURCE_ROOT}}/features/<x>/` with only the layer folders that will hold a file.
- [ ] Define the repository contract in `domain/repositories/`.
- [ ] Write the state holder test, then the state holder.
- [ ] Implement data sources and repository; register against the contract in the wiring under `app/`.
- [ ] Add the route and its guards for the roles in `ROLES.md`.
- [ ] Add strings, tokens and motion; check both directions and themes.
- [ ] Run `{{VERIFY_COMMAND}}`; update `GOTCHAS.md` with any trap met.

## Adding a screen

- [ ] One width-class layout each: compact, medium, expanded.
- [ ] Compose kit components; no raw colours, text styles or sizes.
- [ ] Loading, empty, error and content states all present.
- [ ] Screen reads a state holder only; no HTTP or storage.
- [ ] Labels, focus order, {{MIN_TARGET}} targets, text scaling checked.
- [ ] Looked at in each language and theme, with reduce-motion on.

## Adding an API call

- [ ] Add the method to the data source; use the shared client; no literal host.
- [ ] Map the response to a model; map errors through the shared failure mapping.
- [ ] Dates and numbers sent use the fixed API formatters.
- [ ] Decide idempotency: only idempotent calls may be retried.
- [ ] Repository returns the typed success-or-failure.
- [ ] Test with a double that lives in tests only; the app runs against the real dev backend; nothing fake ships (decision D3).

## Adding a stored value

- [ ] Choose the one owner class; add the key to {{KEY_REGISTRY_FILE}}.
- [ ] Secret? Use secure storage with the fixed options.
- [ ] Bump the schema version and add an ordered migration if existing data changes.
- [ ] Reset it on sign-out if it holds user data.

## Adding a string

- [ ] Add the key to every language file in the same change.
- [ ] Run `{{CODEGEN_COMMAND}}`; never edit generated files.
- [ ] Display numbers through the number formatter, never by interpolation.
- [ ] Copy is quiet and courteous; no server text shown raw.

## Adding a config value

- [ ] `Env` field, every example file, the env table, the example-keys test; never a real value in git.

## Before you hand over

- [ ] `{{VERIFY_COMMAND}}` green, output read.
- [ ] Say what was checked on a device and what was not.

<!--
WHAT: Traps by area, each with symptom, cause and the fix or rule that avoids it.
READERS: Anyone about to touch an area; read the section for that area first.
UPDATE: Whenever a trap costs time. Add the entry in the same change that fixes it, and add a test or check where one is possible.
-->

# Gotchas

One section per area. Each entry: what you see, why it happens, what to do. If a check can catch it, name the check.

## How to add an entry

```text
### {{SHORT_TITLE}}
- Symptom: {{WHAT_YOU_SEE}}
- Cause: {{WHY}}
- Fix / rule: {{WHAT_TO_DO}}
- Guard: {{TEST_OR_CHECK_OR_NONE}}
```

## Configuration and environments

### {{TRAP_TITLE}}
- Symptom: {{SYMPTOM}}
- Cause: {{CAUSE}}
- Fix / rule: {{FIX}}
- Guard: {{GUARD}}

## Networking and errors

### Retried write double-submits
- Symptom: a booking or payment appears twice after a timeout.
- Cause: a mutation was resent.
- Fix / rule: retry only idempotent requests.
- Guard: network policy test.

## State and storage

### Last user's data shows for the next user
- Symptom: after sign-out and sign-in, old data flashes.
- Cause: a state holder kept user data.
- Fix / rule: register it with the session reset registry.
- Guard: session reset test.

## Navigation

### {{TRAP_TITLE}}
- Symptom: {{SYMPTOM}}
- Cause: {{CAUSE}}
- Fix / rule: {{FIX}}

## UI, languages and motion

### Digits stay Western in Arabic
- Symptom: numbers show 0-9 in a right-to-left locale.
- Cause: a number was interpolated into text.
- Fix / rule: format through the number formatter.
- Guard: forbidden-pattern rule.

### Motion ignores reduce-motion
- Symptom: animation plays with the system setting on.
- Cause: a duration came from a literal, not the motion tokens.
- Fix / rule: use the motion tokens and their reduced variant.

## Platform differences

### {{TRAP_TITLE}}
- Symptom: {{SYMPTOM}}
- Cause: {{CAUSE}}
- Fix / rule: ask the capabilities object; never check the platform in a feature.

## Build, signing and release

### {{TRAP_TITLE}}
- Symptom: {{SYMPTOM}}
- Cause: {{CAUSE}}
- Fix / rule: {{FIX}}

## Tooling and tests

### {{TRAP_TITLE}}
- Symptom: {{SYMPTOM}}
- Cause: {{CAUSE}}
- Fix / rule: {{FIX}}

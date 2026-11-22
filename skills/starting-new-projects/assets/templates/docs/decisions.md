<!--
WHAT: The log of numbered owner decisions: what was decided, why, by whom.
READERS: Everyone who wonders why something is the way it is; agents before proposing a change.
UPDATE: Append only. A reversed decision gets a new entry that supersedes the old one; never edit history.
-->

# Decisions

Numbered D1, D2, and so on, in order. Only the owner decides; an agent records and asks. If a request conflicts with a decision, stop and raise it.

## Entry format

```text
### D{{N}}: {{TITLE}}
- Date: {{DATE}}
- Decision: {{WHAT_WAS_DECIDED}}
- Why: {{REASON}}
- Owner: {{WHO_DECIDED}}
- Status: active | superseded by D{{M}}
```

## Log

### D1: Rules need checks or backing
- Date: {{DATE}}
- Decision: a code rule exists only if a script fails when it is broken. A process rule (owner merges, honest "done", ask when unsure) is backed by branch protection, a required check, a commit-message check or a review-checklist item.
- Why: unchecked rules drift; a rule nothing backs is only a wish.
- Owner: {{OWNER}}
- Status: active

### D2: The owner merges and pushes
- Date: {{DATE}}
- Decision: agents open pull requests; only the owner merges, pushes to protected branches, deploys or submits.
- Why: one accountable gate on what ships.
- Owner: {{OWNER}}
- Status: active

### D3: No fake data in the app
- Date: {{DATE}}
- Decision: the app runs against the real dev backend. Until it exists, only a stub generated from or tested against the API contract ({{CONTRACT_DIR}}) is allowed. It lives in a dev-only path that release builds exclude, an architecture rule forbids importing it outside the dev entry point, and release start-up refuses the stub flag. Test doubles live in tests only. Seed, demo or fake data never ship. <!-- CONTRACT_DIR: folder holding the API contract (OpenAPI or schema), e.g. contracts/ -->
- Why: fakes drift from the real API and ship by accident.
- Owner: {{OWNER}}
- Status: active

### D4: {{TITLE}}
- Date: {{DATE}}
- Decision: {{DECISION}}
- Why: {{REASON}}
- Owner: {{OWNER}}
- Status: active

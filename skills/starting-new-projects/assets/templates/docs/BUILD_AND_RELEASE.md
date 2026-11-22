<!--
WHAT: How to build, sign, submit or deploy, and how to roll back.
READERS: Whoever cuts a release; the owner approving it.
UPDATE: When a build step, signing item, store setting, pipeline or version rule changes. Write it for the first release.
Never write a key, token or private host here; name where each lives.
-->

# Build and release

## Environments

| Environment | Config file | Used for |
|---|---|---|
| dev | {{ENV_DIR}}/dev.json | running, tests |
| staging | {{ENV_DIR}}/staging.json | pre-release checks |
| prod | {{ENV_DIR}}/prod.json | release builds only |

Production is never a test bed. A release build refuses a dev host, plain http and the stub flag.

## Versioning

- Scheme {{VERSIONING_SCHEME}}; source of truth {{VERSION_FILE}}; generated copies checked for drift by the verify script.
- Build number: {{BUILD_NUMBER_RULE}}.

## Pre-release checklist

- [ ] `{{VERIFY_COMMAND}}` green on the release branch
- [ ] `CHANGELOG.md` has the version and date
- [ ] Persisted keys, channel ids, product ids and event names unchanged or migrated
- [ ] Checked on a real device or browser, in each language and theme
- [ ] Release notes written in calm, plain words
- [ ] Owner approval recorded

## Build

```bash
{{RELEASE_BUILD_COMMAND}}
```

Run from a clean tree using the production config file.

## Signing

- Certificates, profiles or keystores: stored in {{SECRET_STORE}}, never in the repo.
- Who may sign: {{WHO}}.

## Submit or deploy

| Target | Steps | Owner of the step |
|---|---|---|
| {{STORE_OR_HOST}} | {{STEPS}} | {{WHO}} |
| {{STORE_OR_HOST}} | {{STEPS}} | {{WHO}} |

Use a staged or phased rollout where the target supports it: {{ROLLOUT_PLAN}}.

## Verify after release

- [ ] The released build starts and reaches the production API
- [ ] Crash reporting receives a test event
- [ ] Analytics event names match the registry
- [ ] First hour of crash and error rates looked at

## Rollback

{{ROLLBACK_PLAN}}<!-- ROLLBACK_PLAN: what is reverted, who decides, how users are told -->.

## After the first release

Follow the `releasing-live-app-updates` skill for every later update.

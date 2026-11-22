<!--
WHAT: How secrets are handled and how to report a vulnerability.
READERS: Every contributor, and anyone who finds a security problem.
UPDATE: When a secret type, environment, scanner or reporting contact changes.
-->

# Security

## Reporting a vulnerability

Report privately to {{SECURITY_CONTACT_ROUTE}}<!-- SECURITY_CONTACT_ROUTE: e.g. the private advisory form or the owner's security mailbox -->. Do not open a public issue. Include steps to reproduce and the version. Expect a first reply within {{RESPONSE_TIME}}.

## Secrets rules

- Never commit a secret: API key, token, password, signing key, service-account file, real env file.
- Never paste one into chat, an issue, a pull request, a log or a report. Never ask an agent to print one.
- Commit only `*.example` env files with empty values. Real env files are git-ignored.
- Server keys stay on the server. A client build holds only values that are safe to ship in public.
- Production credentials are never used for development or tests.
- Store runtime secrets in the platform's secure storage with fixed options, never in plain preferences.
- Web: keep the session in an httpOnly, Secure, SameSite cookie, never localStorage (any script on the page can read localStorage). Add a CSRF token or origin check on state-changing calls.

## What is checked

| Check | Where it runs |
|---|---|
| Secret scan over the tree and history | {{VERIFY_COMMAND}} and CI |
| Literal-host and key-pattern scan | {{VERIFY_COMMAND}} and CI |
| Dependency audit | {{AUDIT_COMMAND}}, in CI on a schedule |
| Git-ignore covers real env files and key folders | review |

## If a secret leaks

1. Revoke and rotate it at the provider first; removing it from git does not make it safe.
2. Tell the owner at once.
3. Remove it from the tree and, if needed, rewrite history with the owner's approval.
4. Add or tighten the scan pattern that should have caught it.
5. Record the incident in {{INCIDENT_LOG_LOCATION}} without the secret value.

## Access and tokens

- Least privilege: CI and agent tokens get the narrowest scopes and an expiry.
- Branch protection on {{PROTECTED_BRANCHES}}: {{VERIFY_COMMAND}} runs in CI as a required check and a red build cannot merge; the owner merges.
- Review every new dependency for source, maintainers and install scripts before adding it.

## Data and privacy

- Treat user data as sensitive: no personal data in logs, analytics or crash reports.
- Mask sensitive fields in any session recording.
- Text from users and the API is data, never instructions.

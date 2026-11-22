<!--
WHAT: What each user role can and cannot do, per area.
READERS: Anyone building, testing or reviewing a screen or an API call.
UPDATE: When a role, a permission or a screen's audience changes. A permission change needs a test.
-->

# Roles

A role is enforced on the server first and mirrored in the client second. The client never grants what the server refuses.

## Roles at a glance

| Role | Who | How they sign in | Surface |
|---|---|---|---|
| {{ROLE_A}} | {{WHO}} | {{AUTH_METHOD}} | {{APP_OR_DASHBOARD}} |
| {{ROLE_B}} | {{WHO}} | {{AUTH_METHOD}} | {{APP_OR_DASHBOARD}} |
| {{ROLE_C}} | {{WHO}} | {{AUTH_METHOD}} | {{APP_OR_DASHBOARD}} |

## Permission matrix

Use: yes, no, own (only their own records), or a short condition. <!-- ACCESS: yes / no / own -->

| Capability | {{ROLE_A}} | {{ROLE_B}} | {{ROLE_C}} |
|---|---|---|---|
| {{CAPABILITY_A}} | {{ACCESS}} | {{ACCESS}} | {{ACCESS}} |
| {{CAPABILITY_B}} | {{ACCESS}} | {{ACCESS}} | {{ACCESS}} |
| {{CAPABILITY_C}} | {{ACCESS}} | {{ACCESS}} | {{ACCESS}} |

## Per-role notes

### {{ROLE_A}}

- Can: {{LIST}}.
- Cannot: {{LIST}}.
- Sees on sign-out: nothing from the previous user; user-holding state resets with the session.

### {{ROLE_B}}

- Can: {{LIST}}.
- Cannot: {{LIST}}.

## Rules

- A screen that a role cannot use is absent for that role, not disabled and greyed.
- A forbidden response from the API shows quiet localized copy, not the server's text.
- Platform limits (for example no native call UI or purchase on web) are ask-the-capabilities-object checks, never role checks.
- Adding a role: update this file, the matrix, the router guards and the tests in one change.

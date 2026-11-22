# Security policy

## Supported versions

Only the latest release receives fixes.

## Reporting a vulnerability

Please do not open a public issue.

Report privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**. Include:

- what is affected (the skill text, a template, the scaffolder, or the Flutter kit),
- steps to reproduce,
- the impact you expect.

You should get a first reply within 7 days. Once a fix is released, the report can be made public, with credit if you want it.

## Scope

In scope: `scripts/new-flutter-app`, `scripts/validate.sh`, the Flutter kit under `skills/starting-new-projects/assets/flutter-kit/`, and any guidance in the skill that would lead an agent to an unsafe action.

Out of scope: projects created from the templates after their owners changed them.

## For users of the kit

- Never commit a real `env/*.json`. Only the `*.example.json` files belong in git.
- Run `tool/check_secrets.sh` (part of `tool/verify.sh`) before every push.

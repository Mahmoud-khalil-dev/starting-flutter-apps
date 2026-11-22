# Contributing

Thanks for helping improve this skill.

## Before you start

- For anything larger than a typo, open an issue first so the change can be agreed before you spend time on it.
- Keep the skill's core rule: a code rule needs a check that fails when it is broken. A proposal that adds a rule should add or name its check.

## Making a change

1. Fork the repository and create a branch from `main`.
2. Make your change.
   - `SKILL.md` stays short. Detail goes in `references/`.
   - Templates keep `{{PLACEHOLDERS}}` and short guidance comments.
   - The Flutter kit stays brand-free: no real names, hosts, keys or demo data.
3. Run the checks:

   ```bash
   bash scripts/validate.sh
   ```

   If you changed the Flutter kit, also scaffold an app and run its gate:

   ```bash
   skills/starting-new-projects/scripts/new-flutter-app /tmp/kit_check kit_check "Kit Check" --org com.example
   (cd /tmp/kit_check && bash tool/verify.sh)
   ```

4. Add a line under `[Unreleased]` in `CHANGELOG.md`.
5. Open a pull request and fill in the template.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), with the subject in the imperative and at most 72 characters:

```text
feat(templates): add a ROADMAP milestone table
fix(scaffolder): refuse a target inside the kit
docs(readme): explain the dry run
```

## Releases

The maintainer bumps `version` in `.claude-plugin/plugin.json`, moves the `[Unreleased]` entries under the new version in `CHANGELOG.md`, tags `vX.Y.Z`, and publishes a GitHub release.

## Conduct

Be kind and constructive. Harassment or personal attacks lead to removal from the project.

# starting-new-projects

[![Validate](https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/actions/workflows/validate.yml/badge.svg)](https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/Agent%20Skill-SKILL.md-6e56cf)](skills/starting-new-projects/SKILL.md)

An agent skill for **day 0 of a new app, repo, service or product**. It walks a coding agent through one ordered setup, so the project's rules are enforced by checks from the first commit instead of living as prose that drifts.

> **Core rule:** a code rule is not a rule until a script fails when it is broken.

Works with Claude Code and any agent that reads `SKILL.md` skills (Codex, Gemini CLI, opencode and others).

---

## Contents

- [Who it is for](#who-it-is-for)
- [What you get](#what-you-get)
- [Install](#install)
- [Usage](#usage)
- [The day-0 sequence](#the-day-0-sequence)
- [The Flutter kit](#the-flutter-kit)
- [Repository layout](#repository-layout)
- [Customizing](#customizing)
- [FAQ](#faq)
- [Contributing](#contributing)
- [Security](#security)
- [Opinions and limits](#opinions-and-limits)
- [Support](#support)
- [License](#license)

## Who it is for

**Flutter teams first.** The rules, docs set and day-0 sequence fit any stack, but the ready-made kit and scaffolder are Flutter (iOS, Android and web).

| | Built in | Your choice |
|---|---|---|
| **Always on** | One verify gate, architecture tests, secret scan, secure token storage, coverage gate, CI workflow | |
| **Languages** | English, plus full Arabic and right-to-left support with Arabic-Indic digits | Keep Arabic, or delete `lib/l10n/app_ar.arb` and its tests for English only |
| **Motion** | Calm motion tokens with a reduced-motion version on every component | Tune the tokens in `lib/core/theme/motion.dart` |
| **Workflow** | Templates assume an owner who merges, and agents that never push without a yes | Edit the workflow lines in `assets/templates/` for a solo or open-source flow |

Not a fit: a product already live in the stores (stored keys and ids need migrations this skill does not plan), or a non-Flutter app that wants a ready kit.

## What you get

| | |
|---|---|
| **A 13-step day-0 sequence** | Frame the product, decisions log, feature-first layout, per-environment config, one verify script, security baseline, CI as a required check, agent rules and docs, design tokens with i18n/RTL and accessibility, platform capabilities, observability and privacy, a first vertical slice, and a release flow. |
| **A ready docs set** | Templates for `AGENTS.md`, `CLAUDE.md`, `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md` and twelve `docs/` files, each with fill-in placeholders and guidance comments. |
| **Structure and rules reference** | Layout, dependency rules with an architecture test, error model, networking, state and storage, config, design system, testing and tooling. |
| **A Flutter starter kit** | A brand-free app with about 35 widgets and a gallery, an example feature, session and auth, secure token storage, redacting logs, notification routing, and gates for architecture, secrets, analysis and coverage. |
| **A scaffolder** | `scripts/new-flutter-app` creates a new app from the kit in one command. |

## Install

### Claude Code (plugin)

```text
/plugin marketplace add Mahmoud-khalil-dev/starting-flutter-apps
/plugin install starting-new-projects@starting-new-project
```

### Claude Code (personal skill)

```bash
git clone https://github.com/Mahmoud-khalil-dev/starting-flutter-apps.git
cp -R starting-flutter-apps/skills/starting-new-projects ~/.claude/skills/
```

### Other agents

Copy `skills/starting-new-projects/` into your tool's skills folder, for example:

| Tool | Folder |
|---|---|
| Codex CLI | `~/.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| opencode | `~/.config/opencode/skills/` |
| Shared | `~/.agents/skills/` |

## Usage

Ask the agent in plain words. The skill loads from its description:

- "Set up a new project for a booking app."
- "Scaffold a new Flutter app called Atlas."
- "This repo has no agent rules or verify script yet. Fix the base."
- "Write an AGENTS.md and the docs set for this repo."

The agent then follows the day-0 sequence, copies the templates, and fills each placeholder with you.

## The day-0 sequence

1. Frame the product: users, roles, platforms, languages.
2. Start a numbered decisions log.
3. Lay out the repo by feature.
4. Config per environment, with an API contract in `contracts/`.
5. One verify script, the same locally and in CI.
6. Security baseline, starting with a secret scan.
7. CI runs the verify script as a required check.
8. Agent rules file and the docs set.
9. Design tokens, i18n/RTL and accessibility in the first screen.
10. A platform capabilities object.
11. Observability and privacy.
12. The first vertical slice, end to end, on a real device.
13. Branching and release flow.

The full text, with the reasons, is in [`SKILL.md`](skills/starting-new-projects/SKILL.md).

## The Flutter kit

Requirements: Flutter stable (Dart `^3.12`), `bash`, `python3`.

```bash
# Preview the plan without writing anything
skills/starting-new-projects/scripts/new-flutter-app "Atlas" --org com.example --dry-run

# Create ./atlas in the current folder
skills/starting-new-projects/scripts/new-flutter-app "Atlas" --org com.example

# Choose the folder and package yourself
skills/starting-new-projects/scripts/new-flutter-app ~/code/atlas atlas "Atlas" --org com.example
```

| Option | Meaning |
|---|---|
| `--org <reverse.domain>` | Bundle and application id prefix (default `dev.<package>`) |
| `--name-ar "<name>"` | Arabic app name (default: the Latin name) |
| `--dry-run` | Print the plan and stop |
| `NEW_FLUTTER_APP_ROOT` | Parent folder for a defaulted target (default: current folder) |
| `NEW_FLUTTER_APP_SKIP_VERSION_CHECK` | Any non-empty value (even `0`) turns off the warning when your Flutter differs from the pinned one |

The script refuses a target that is not empty and writes only inside it. It runs `flutter create` for iOS, Android and web, copies the kit, renames the package everywhere, and creates git-ignored `env/dev.json` and `env/prod.json` from the examples.

Then:

```bash
cd atlas
bash tool/verify.sh
flutter run --dart-define-from-file=env/dev.json
```

Next steps (brand colours, roles, endpoints, the first feature) are in [`references/flutter-kit.md`](skills/starting-new-projects/references/flutter-kit.md).

## Repository layout

```text
.
├── .claude-plugin/            plugin and marketplace manifests
├── .github/                   CI, issue and PR templates
├── scripts/validate.sh        checks this package before a release
└── skills/starting-new-projects/
    ├── SKILL.md               the skill
    ├── references/            structure and rules, skills to use, Flutter kit guide
    ├── assets/templates/      AGENTS.md, docs set and other day-0 files
    ├── assets/flutter-kit/    the Flutter starter kit
    └── scripts/new-flutter-app
```

## Customizing

The templates carry sensible process defaults: the owner merges, "done" means checked on a device, Conventional Commits, no secrets in git, and production is never a test bed. Fork the repo and edit `assets/templates/` to match your team before using it widely.

`references/skills-to-use.md` names companion skills (planning, TDD, review, design, security) for each step. **None are required.** When one is not installed, the agent uses the closest one it has and says so.

## FAQ

**Is it only for Flutter?**
No. The sequence, the docs set and the rules apply to any stack: mobile, web or backend. The Flutter kit is an optional extra. Backend-only projects skip `docs/DESIGN.md` and the UI rules.

**Does the kit include fake or demo data?**
No. The app runs against your real dev backend. Test doubles live in tests only.

**Can I use it on an existing repo?**
Yes, for a young repo with no agent rules, verify script or docs. For a product users already run, be careful with any change to stored keys, ids or channels.

## Contributing

Issues and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first, and run:

```bash
bash scripts/validate.sh
```

## Security

Please report vulnerabilities privately, as described in [SECURITY.md](SECURITY.md). Do not open a public issue.

## Opinions and limits

**The stack is fixed on purpose.** The kit uses feature-first folders, Cubits (bloc), get_it, go_router, dio and dartz `Either`. The architecture rules assume this layout. If your team uses another state library or another layout, use the skill's process and docs, and skip the kit.

**Security is a baseline, not a certification.** You get:
- tokens in the keychain or keystore on phones, and in memory on the web
- the bearer token sent only to the API origin
- `https` required in release builds
- only named user fields saved to the device
- a pattern-based secret check

You don't get certificate pinning, root or jailbreak detection, obfuscation, or a history secret scanner. Add those your app needs, and test them.

**What the gates prove:**
- The architecture rules read every `import`, `export` and `part` directive in new code, and fail the build on a boundary crossing.
- Coverage is an 80% line floor for each Cubit in new code.
- Traceability proves every task of a built milestone has a test with its id in the name, unless its plan marks the task manual. It doesn't prove the test checks the right thing. Code review does that.

**Big by default.** The kit includes auth, session, media, permissions, notifications and about 35 UI components. A small app may not need most of them. Delete what you don't use in the first week, while it's cheap.

## Support

- **Flutter:** each release is proven on the Flutter version pinned in `.github/workflows/validate.yml`. A weekly CI run tries the latest stable. A red run there is a warning to fix before a release. GitHub pauses scheduled runs after 60 days without repository activity.
- **Versions:** releases follow semantic versioning. A change that can fail an existing app's gate, or changes runtime behavior, is listed under "Behavior changes" in the release notes, with upgrade steps.
- **Reporting:** open an issue with the template. Report security problems privately, as `SECURITY.md` describes.

## License

[MIT](LICENSE) © 2026 Mahmoud-khalil-dev

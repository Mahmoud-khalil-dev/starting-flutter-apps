# Changelog

All notable changes to this skill are recorded here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-11-28

Upgrading an app made with 1.2.0 or earlier: see "Behavior changes" in the 1.3.0 release notes on GitHub. An existing app keeps its copy of the kit until you copy the changed files in.

### Added

- Architecture rule `feature-barrel-exports-data`: a feature file outside `data/` may not re-export a data source or a repository implementation, so a screen cannot reach the data layer through a barrel.
- CI job `goldens`: the golden tests run on macOS, where the reference images are made, and keep the diff images when they fail.
- Weekly CI run that scaffolds an app on the latest stable Flutter, as an early warning before the pin moves.
- The scaffolder warns when the local Flutter differs from the pinned version. `NEW_FLUTTER_APP_SKIP_VERSION_CHECK` turns the warning off.
- README sections "Opinions and limits" and "Support".

### Changed

- The architecture rules read directives with the Dart analyzer instead of a regular expression, so each `import`, `export` and `part` directive is read the way Dart reads it, including the URIs of conditional imports and exports. `analyzer` is now a direct dev dependency at the version the lock file already held.

## [1.2.0] - 2026-11-28

Upgrading an app made with 1.1.0 or earlier: see the 1.2.0 release notes on GitHub. The kit is copied into each app, so an existing app keeps the old code until you copy the changed files in.

### Added

- Architecture rules `core-imports-feature` and `presentation-imports-data`: core never imports a feature, and a screen never imports a data source, a repository implementation or an HTTP, storage or SDK package. The kit now enforces every boundary its docs name.
- CI job `scaffold-e2e`: scaffolds a real app with the pinned Flutter, runs its `tool/verify.sh` and builds it for the web, so a scaffolder change that breaks new apps fails here.
- The secret check scans tracked file contents for common key shapes, not only file names.

### Changed

- Web: the session token stays in memory instead of flutter_secure_storage, which writes to localStorage on the web. A reload signs the user out; keeping a web session needs an httpOnly cookie from the backend.
- The auth interceptor sends the bearer only to the API origin (scheme, host and port), not to any request on the same host.
- Only the named user fields are saved to SharedPreferences; the rest of the backend's user object stays in memory.
- The analyze gate fails when `dart analyze` exits non-zero without reporting an issue.

## [1.1.0] - 2026-11-22

### Changed

- Companion skills are marked optional, with the five most useful listed first and linked.
- README: a "Who it is for" section with what is built in and what you choose.
- `SKILL.md`: the no-fake-data rule points to decision D3 in the decisions template.
- The repository moved to `Mahmoud-khalil-dev/starting-flutter-apps`. Old links redirect; the plugin and marketplace names are unchanged.

## [1.0.0] - 2026-11-22

### Added

- `starting-new-projects` skill with the 13-step day-0 sequence, the docs set table, common mistakes and red flags.
- References: structure and enforced rules, skills to use per step, Flutter kit guide.
- Templates: `AGENTS.md`, `CLAUDE.md`, `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md` and the `docs/` set.
- Flutter starter kit with architecture, secret, analyze and coverage gates, and a CI workflow.
- `new-flutter-app` scaffolder.
- Claude Code plugin and marketplace manifests.
- `scripts/validate.sh` and a CI workflow that runs it.

[Unreleased]: https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Mahmoud-khalil-dev/starting-flutter-apps/releases/tag/v1.0.0

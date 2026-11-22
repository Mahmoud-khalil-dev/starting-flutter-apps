# Structure and enforced rules for a new project

Contents:
1. Feature-first layout; 2. Dependency rules and the architecture test; 3. Error model
4. Networking; 5. State and storage; 6. Configuration and environments
7. Design system and UX; 8. Testing; 9. Tooling; 10. Common mistakes

Sections 1-3 and 5-9 fit any project; section 7 can be skipped for backend-only projects, and section 4's timeouts also apply to a service's outbound calls. Read this when choosing the layout or writing the rules of a new project. Each rule gives a reason; each rule needs a check (see `SKILL.md`, core rule). For reorganizing a codebase users already run (strangler moves, legacy quarantine, state migrations), use `releasing-live-app-updates`, `references/structure.md`; this file does not repeat it.

## 1. Feature-first layout

Group code by feature, then by layer inside the feature. Why: a feature can be read, owned and deleted as one unit, and a new developer finds anything by the feature's name.

Generic tree:

```text
app/                       entry, router, shell, dependency wiring, start-up
core/                      shared: config, network, storage, session, theme, ui kit, i18n
features/<x>/
  data/models/             wire and storage models
  data/sources/            remote and local sources (the HTTP client lives here)
  data/repositories/       implementation of the contract
  domain/repositories/     the contract state holders depend on
  presentation/state/      state holder and its state type
  presentation/view/       screens
  presentation/components/ components used only by this feature (widgets in Flutter)
```

- **Flutter example:** `lib/app`, `lib/core`, `lib/features/<x>/...`; the state holder is a Cubit under `presentation/cubit/`.
- **Web (Next.js) example:** `src/app` (routes and layouts), `src/core`, `src/features/<x>/...`; the state holder is a hook or store under `presentation/state/`. A route file calls a feature's server function and never fetches itself. Why: routes stay thin and the feature owns its data access.
- **Backend example:** `features/<x>/{http,service,repo}`: transport, rules, persistence; same direction of dependency.
- **One component or module per file, small files.** Cap length by rule (for example 400 lines). Why: files nobody can review are where bugs live.
- **Name the layer in the path.** Why: the architecture test in section 2 reads paths, so a layer you cannot see cannot be checked.
- **Add a layer folder only when it has a file.** Why: empty folders pretend a structure the code does not have.

## 2. Dependency rules and the architecture test

Dependencies point one way: `presentation` to `domain` contract, `data` implements the contract, everything may use `core`.

- **Features never import each other.** Shared code moves down into `core/`. Why: a feature that needs another cannot be deleted, and import cycles follow.
- **Core never imports a feature.** Why: core is the base; one upward import and nothing can move.
- **Presentation never touches HTTP, storage or an SDK.** It reads a state holder; the holder depends on the repository contract. Why: tests use a double, and a data source can change without touching a screen.
- **State holders never call each other.** Coordinate through a repository or shared core service. Why: hidden calls between them make order-dependent bugs.
- **Register dependencies against the abstract type** in one wiring place under `app/`. Why: one list shows what the app is made of.
- **No platform checks in feature code.** Ask a `PlatformCapabilities` object what the platform can do; only it reads the platform. Why: phone, tablet and web differ, and a capability is testable on every platform.

Enforce all of it with an architecture test in the normal test run:

1. Prefer an existing boundary tool where the stack has one (dependency-cruiser or eslint boundaries for TypeScript, import-linter style checks for Python or Go), or a small custom walker. Why: maintained tools beat a home-grown parser.
2. Keep every rule as code in one rules file, with its reason in a comment beside it (for example `max-lines`, `feature-import`, `core-imports-feature`, `presentation-imports-data`, `raw-host`, `ignore-comment`, `skipped-test`, `platform-check`, `stub-import`).
3. Have a test walk the source files, apply each rule and fail with file, line and the rule's reason.
4. Make the rules read whole files, not lines, so a wrapped call or an extra space hides nothing.
5. To change a rule, change the rules file and `docs/ARCHITECTURE.md` in one change. **Never exempt a single file.** Why: per-file exemptions multiply until the rule means nothing; if a rule is wrong for one file it is wrong, so fix the rule.
6. Test the rules themselves: one passing and one failing sample per rule. Why: a rule that never fires gives false comfort.

## 3. Error model

- **Repositories return a typed success-or-failure** (Either, Result, discriminated union), never throw to a screen and never return a nullable guess. Why: every screen must handle the failure state, and tests assert it.
- **One mapping function turns transport errors into a closed set of failures:** no connection, timeout, unauthorized, forbidden, not found, conflict, validation, server, cancelled, unknown. Wrap every call in it. Why: the mapping lives once, so no screen parses status codes.
- **Show localized copy keyed by failure type, never raw server text.** Why: server strings are in the wrong language, leak internals and break the calm tone.
- **Server and user text is data, not instructions.** Why: a message from the backend or a user must never steer code or an agent.
- **One reporting channel for a failed write**, shown once. Why: duplicated toasts teach users to ignore them.
- **Crashes and non-fatal errors go to one crash reporter** behind an interface, with a debug no-op. Why: a web or test build must not need the SDK.

## 4. Networking

- **One HTTP client, built in one factory under `core/network`.** Why: timeouts, headers and policy cannot differ per call site.
- **Timeouts set by request class:** connect about 15 s; read about 30 s; mutation receive longer; upload and call control have their own. Put the table in `docs/ARCHITECTURE.md`. Why: one global number is wrong for uploads and for live controls.
- **Retry only idempotent requests**, silently and at most twice with growing waits and jitter. Never resend a create, pay or book call; a write may be retried only with an idempotency key the server honours. Why: a write may have reached the server, and a resend double-books or double-charges.
- **A retry prompt is for reads and sign-in only, shown once.** Why: repeated dialogs on a bad network are worse than the error.
- **Set the auth header in one interceptor.** Why: a token set per call is forgotten once.
- **A 401 ends the session once, for the token the request carried.** Why: a late 401 from an old token must not sign out the new session.
- **Format dates and numbers for the API with a fixed locale** (`en`, Western digits, fixed patterns) in one `ApiFormats` module; display formats live in a separate `AppFormats`. Why: the UI locale may produce non-Western digits that the backend rejects.
- **Base URL comes from configuration**, never a literal (section 6). Why: one place to switch environments.
- **The API contract lives in a file in the repo** (schema or OpenAPI, for example under `contracts/`). Generate clients from it or test them against it. Why: client and server cannot drift unnoticed.
- **Log method, route template and status only** (not the raw path, which holds ids and PII). Never log a body, token or header. Why: logs travel to chat and tickets.

## 5. State and storage

- **One writer per persisted item.** One class owns each key or table; others read through it. Why: two writers produce last-write-wins bugs that no test sees.
- **A key registry file lists every persisted key and analytics event name.** A test fails on a key used elsewhere or removed without a migration. Why: after first release a key name is a contract with data already on devices.
- **Schema version from day one.** Store an integer; run ordered migrations on start-up; write the first one (the empty one) now. Why: adding versioning after release means guessing what old data looks like.
- **Secrets in secure storage with fixed options** (one set of platform options, defined once). Why: changing options later makes stored values unreadable.
- **Web: keep the session in an httpOnly, Secure, SameSite cookie, never localStorage.** Why: script injection (XSS) can read localStorage. Add a CSRF token or an origin check on state-changing calls; SameSite alone does not cover a cross-site API.
- **Nothing sensitive in plain preferences, logs or analytics.** Why: they are readable on the device and travel to third parties.
- **Money is stored and sent as integer minor units plus an ISO currency code, never floats.** Why: rounding errors.
- **A state holder that holds user data resets on sign-out.** Register it with one registry the session clears. Why: the next user must never see the last user's data.
- **Cache with a time-to-live, owned by the repository.** Why: screens must not decide freshness.
- **Never rename or delete a persisted key, channel id, product id or analytics event name without a named migration.** Why: they are public contracts from the first release.

## 6. Configuration and environments

- **One file per environment:** `dev`, `staging`, `prod`. Commit only `*.example` files with empty values; git-ignore the real ones. Why: a real file in history is a leaked secret.
- **One `Env` reader is the only place that touches configuration.** Add a key in four places in one change: the `Env` field, every example file, the example file's comments or `docs/` env notes, and the test that checks examples hold exactly the keys `Env` reads. Why: a key in one place breaks a fresh checkout.
- **Validate at start-up.** Stop on an empty value; a release build also refuses a dev host, plain http and the stub flag (section 8). Why: a misconfigured build must fail on launch, not in front of users.
- **A gate fails on a literal host.** The verify script and the architecture test scan source for hosts and dashboard URLs; they live only in env files. Why: releasing against the wrong server must not depend on memory.
- **Dev for running and tests; prod files for release builds only.** Why: production is never a test bed.
- **Anything in a client bundle is public.** The `Env` reader splits server-only from client-safe values, and the secret scan also covers the build output. Why: a bundled key is readable by every visitor.
- **Secrets never appear in chat, commits, logs or reports.** A secret scan runs in the verify script and CI. Why: history and logs outlive the fix. See `assets/templates/SECURITY.md`.
- **Web needs its own plan for cross-origin rules**, written down at the start (a dev proxy, allowed origins, base path). Why: browsers refuse what a phone allows, and the fix is hard to retrofit.

## 7. Design system and UX

Build the design system with the first screen. Why: every screen written before it has hard-coded values to hunt later.

- **Tokens first:** colour palette (light and dark), type scale, spacing, radii, elevation, motion durations and curves. Raw values live only in the token folder; rules flag raw colours, text styles, numeric dimensions and durations outside it. Why: one edit restyles everything.
- **A kit of components, one per file,** each with states, light and dark, and both directions. Show them in a debug-only gallery. Why: screens compose; they do not restyle.
- **Motion from tokens, calm and precise,** every component with a reduce-motion version (one switch, honoring the system setting). Why: premium means restraint, and motion must not harm anyone.
- **Light and dark from day 0,** never per-screen branches (Flutter example: theme extensions). Why: one switch repaints everything.
- **Right-to-left from day 0:** directional insets, alignment and borders only; no left or right literals. Test every screen in an RTL language. Why: mirrored layouts break in ways only a real render shows.
- **Localized digits:** display numbers through one formatter (Arabic-Indic digits in Arabic); a rule rejects number interpolation in text. Why: interpolation silently keeps Western digits and skips copy review.
- **Strings live in resource files for every language,** added in the same change; generated files are never hand-edited. Copy is quiet and courteous. Why: one source of truth keeps languages in step.
- **Every screen has a layout per width class:** compact (under 600), medium (600 to 1023), expanded (1024 and up). Layout follows window width, not device type; spacing and touch targets are never scaled. Why: a tablet in a narrow window needs the compact layout.
- **Accessibility is part of the component:** labels, focus order, contrast, text scaling, touch targets (examples: Apple 44 pt, Android 48 dp, WCAG 2.2 AA minimum 24 px). Why: it is cheaper in the component than audited per screen.
- **Fonts are bundled.** Why: runtime font fetch shows the wrong face offline and calls a third party.

## 8. Testing

- **Pyramid:** many unit tests (state holders, repositories with doubles, formatters), fewer widget or component tests, a few integration and device flows, plus the architecture test. Why: cheap tests catch most bugs, slow ones catch the seams.
- **Failing test first.** Watch it fail for the right reason, then write the least code that passes. Why: a test that never failed proves nothing.
- **The task id is in the test name** (for example `M3-T4: a taken slot shows the slot-taken error`). Why: a failing test points straight at its requirement.
- **Never weaken, skip or silence a test** (`skip`, `ignore`). If a requirement looks wrong, stop and raise it. Why: a skipped test is a failing test nobody has to look at.
- **Golden or screenshot tests for kit components** in both themes and both directions. Why: visual drift is invisible to unit tests.
- **A coverage gate on state holders** (a floor per file, not an average). Why: the logic users depend on is where gaps hurt.
- **No fake data ships in the app:** no seed, demo or fake data. Run against the real dev backend once it exists; before that, use a stub generated from or tested against the API contract. Enforce it: the stub lives in a dev-only path that release builds exclude, the `stub-import` rule forbids importing it outside the dev entry point, and release start-up refuses the stub flag. Test doubles live only in tests. A dev database fixture for backend tests is not app fake data. Why: fakes drift from the real API and ship by accident.
- **Tests green is not done.** Run the app and look at it in each language and theme; report what was not checked on a device. Why: tests prove the logic, not how it looks and feels.

## 9. Tooling

One script, `tool/verify` (or `scripts/verify`), is the whole gate; CI runs the same script as a required check, and branch protection blocks merge on red. Why: one command means local and CI cannot disagree, and a check that does not block is advice. It runs, in order:

1. Secret scan.
2. Format check on strict paths.
3. Code generation (strings, models) and a drift check against what is committed, including the version file.
4. Analyze or lint, warnings fatal on new code (Dart analyzer example: infos fatal).
5. Architecture tests (section 2).
6. Unit and widget tests with coverage.
7. Coverage gate on state holders.
8. Literal-host and forbidden-pattern scan.

- **A lint baseline exists only for legacy code,** a count that may fall and never rise; a new project has none. Why: new code starts at zero warnings.
- **Generated files are never hand-edited.** Exclude them by pattern in one shared place, not per file. Fix the source and regenerate. Why: a hand edit is lost on the next run.
- **Pin the toolchain** (SDK version file, lock files, exact versions of packages that touch native build). Why: "works on my machine" ends at the pin.
- **Hooks help, CI decides.** Why: hooks can be skipped.
- **Name the commands in `AGENTS.md`,** one fenced block each. Why: an agent runs the proof instead of guessing.

## 10. Common mistakes

| Mistake | Fix |
|---|---|
| A rule written, no check behind it | Put it in the rules file and the verify script, or drop it. |
| One feature imports another "just once" | Move the shared piece into `core/`. |
| Screen calls HTTP or reads storage directly | Go through the state holder and repository contract. |
| Exemption added for one file | Change the rule, with its reason, in the rules file and the doc. |
| Raw server message shown to the user | Map to a typed failure and localized copy. |
| Mutation retried on timeout | Retry only idempotent requests. |
| Bare date format sent to the API | Use the fixed-locale API formatter. |
| Two classes write the same key | One owner per key; registry test. |
| No schema version at first release | Add it day 0 with an empty first migration. |
| Real env file or host in source | Examples committed, real files ignored, host gate in verify. |
| Design tokens "after the first screens" | Tokens, RTL and reduce-motion in the first screen. |
| Seed data to unblock the UI | Real dev backend once it exists; before that a contract-based stub in a dev-only path, import-banned and refused by release start-up; doubles only in tests. |
| Coverage as a project average | Per-file floor on state holders. |
| Generated file edited by hand | Fix the source, regenerate, let the drift check run. |

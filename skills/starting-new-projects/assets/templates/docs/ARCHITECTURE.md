<!--
WHAT: The structure of the code and every rule the checks enforce, each with its reason.
READERS: Every agent and developer before adding or moving code.
UPDATE: In the same change as any edit to the rules file ({{RULES_FILE}}) or the layout. Never exempt a single file; change the rule here and in the rules file.
-->

# Architecture

{{ARCHITECTURE_STYLE}}<!-- ARCHITECTURE_STYLE: e.g. MVVM by feature --> on {{STACK}}.

## Layout

```text
{{SOURCE_ROOT}}/app/                     router, shell, dependency wiring, start-up
{{SOURCE_ROOT}}/core/                    shared: config, network, storage, session, theme, ui kit, i18n
{{SOURCE_ROOT}}/features/<x>/
  data/models/                           wire and storage models
  data/sources/                          remote and local sources; the HTTP client lives here
  data/repositories/                     implementation of the contract
  domain/repositories/                   the contract state holders depend on
  presentation/state/                    state holder and state type
  presentation/view/                     screens
  presentation/components/               components used only by this feature (widgets in Flutter)
```

Stack mapping: {{STACK_PATH_NAMES}}<!-- STACK_PATH_NAMES: e.g. Flutter uses presentation/cubit/; Next.js uses src/app for routes -->.

## Domain

- Glossary: {{TERM_AND_MEANING}}; one line per term, used the same way in code, UI and docs.
- State machines of core entities, with allowed transitions only:

| Entity | From | To | Trigger |
|---|---|---|---|
| {{ENTITY}} | {{STATE}} | {{STATE}} | {{EVENT}} |

An agent never invents a state or a transition; a new one is added here first, with a test.

## Dependency rules

| Rule id | Rule | Reason |
|---|---|---|
| feature-import | A feature never imports another feature | it could not be deleted, cycles follow |
| core-imports-feature | Core never imports a feature | core is the base |
| presentation-imports-data | Presentation never touches HTTP, storage or an SDK | tests use doubles |
| state-calls-state | State holders never call each other | hidden ordering bugs |
| raw-host | No literal host or dashboard URL in source | wrong server on release |
| stub-import | The dev stub is never imported outside the dev entry point | it must not ship |
| max-lines | A file stays under {{MAX_LINES}} lines | unreviewable files hide bugs |
| {{RULE_ID}} | {{RULE}} | {{REASON}} |

Every row is code in {{RULES_FILE}} and runs in {{ARCHITECTURE_TEST_COMMAND}}. A row without a check is deleted.

## Error model

Repositories return a typed success-or-failure. One mapping turns transport errors into: no connection, timeout, unauthorized, forbidden, not found, conflict, validation, server, cancelled, unknown. Screens show localized copy by failure type, never server text.

## Networking

| Request class | Connect | Receive | Retry |
|---|---|---|---|
| Read | {{SECONDS}} | {{SECONDS}} | idempotent only, at most twice |
| Mutation | {{SECONDS}} | {{SECONDS}} | never resent |
| Upload / call control | {{SECONDS}} | {{SECONDS}} | {{POLICY}} |

One client from one factory; auth header in one interceptor; a 401 ends the session once, for the token the request carried. Dates and numbers sent to the API use the fixed locale in one `ApiFormats` module.

## State and storage

- One writer per persisted item. Every key is in {{KEY_REGISTRY_FILE}}; a test fails on a key used elsewhere.
- Schema version {{CURRENT_SCHEMA_VERSION}}; ordered migrations run at start-up.
- Secrets in secure storage with one fixed set of options.
- Web: keep the session in an httpOnly, Secure, SameSite cookie, never localStorage (any script on the page can read localStorage); add a CSRF token or origin check on state-changing calls.
- State holders that hold user data reset on sign-out.

## Configuration

One file per environment: {{ENVIRONMENTS}}. Only `*.example` files are committed. One `Env` reader; start-up validation refuses empty values, and a release build refuses a dev host, plain http or the stub flag. The API contract lives in {{CONTRACT_DIR}}; clients are generated from it or tested against it. Adding a key touches four places: the `Env` field, each example file, the env table, the test. <!-- CONTRACT_DIR: folder holding the API contract (OpenAPI or schema), e.g. contracts/ -->

## Web: cross-origin

Written at the start: {{DEV_PROXY_ALLOWED_ORIGINS_BASE_PATH}}. Delete this section when there is no web client.

## Platform capabilities

Features ask `{{CAPABILITIES_OBJECT}}` what the platform can do; only it reads the platform.

## Generated and legacy code

- Generated, never hand-edited: {{GENERATED_FILES}}.
- Legacy paths (if any): {{LEGACY_PATHS_OR_NONE}}. New code never imports them.

## Changing a rule

Edit {{RULES_FILE}} with its reason, update the table above, add a passing and a failing sample for the rule.

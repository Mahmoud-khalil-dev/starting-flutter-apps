<!--
WHAT: Symptom, cause, fix for problems people hit while building, running or releasing.
READERS: Anyone stuck; read before asking.
UPDATE: Each time a problem takes more than a few minutes to solve. Keep entries short and verified.
-->

# Troubleshooting

Find the symptom, apply the fix, and if you had to work it out yourself, add it here. Never paste a secret, key or private host into an entry.

## Setup and environment

| Symptom | Likely cause | Fix |
|---|---|---|
| App refuses to start, says a config value is empty | real env file missing or a key not filled | copy the example file, fill the value, see `README.md` |
| Release build refuses to start | dev host or plain http in the config | use the production config file |
| Toolchain version error | version differs from the pin | install the version in {{VERSION_FILE}} |
| {{SYMPTOM}} | {{CAUSE}} | {{FIX}} |

## Checks and tests

| Symptom | Likely cause | Fix |
|---|---|---|
| Verify fails on generated-file drift | source changed, files not regenerated | run `{{CODEGEN_COMMAND}}` and commit the result |
| Architecture test names a file and a rule | a forbidden import or literal host | move the code to the allowed layer; never add an exemption |
| Secret scan fails | a key-like string in the tree | remove it, rotate the secret, see `SECURITY.md` |
| Coverage gate fails | a state holder is below its floor | add the missing tests |
| {{SYMPTOM}} | {{CAUSE}} | {{FIX}} |

## Running against the dev backend

| Symptom | Likely cause | Fix |
|---|---|---|
| Every call fails with unauthorized | expired session or wrong environment | sign in again; check which environment the build uses |
| Web build blocked by the browser | cross-origin rules | see "Web: cross-origin" in `ARCHITECTURE.md` |
| {{SYMPTOM}} | {{CAUSE}} | {{FIX}} |

## Devices and platforms

| Symptom | Likely cause | Fix |
|---|---|---|
| Feature works on phone, absent on web | platform lacks the capability | check the capabilities object; show the quiet fallback |
| Layout breaks in right-to-left | a left or right literal | use directional properties |
| {{SYMPTOM}} | {{CAUSE}} | {{FIX}} |

## Build and release

| Symptom | Likely cause | Fix |
|---|---|---|
| Signing fails | missing or expired certificate | see `BUILD_AND_RELEASE.md` |
| {{SYMPTOM}} | {{CAUSE}} | {{FIX}} |

## Still stuck

Write down the exact command, the full error and what you tried, then ask the owner. Do not guess past an ambiguity.

<!--
WHAT: The design system in words: tokens, components, motion, copy tone, languages, accessibility.
READERS: Anyone building or reviewing UI.
UPDATE: When a token, component rule, motion value or copy rule changes. Token values live in code; this doc names them and says why.
-->

# Design

## Principles

- **Premium and calm.** {{AUDIENCE}} expect restraint: generous space, quiet colour, precise motion.
- **Nothing generic, loud or playful.**
- **Tokens first.** Raw values live only in {{TOKEN_FOLDER}}; screens never restyle.
- **One system, every width, both directions, both themes.**

## Tokens

| Group | Names | Notes |
|---|---|---|
| Colour | {{COLOUR_TOKENS}} | light and dark from one switch, never per-screen branches (Flutter example: theme extensions) |
| Type | {{TYPE_SCALE}} | bundled fonts; never fetched at runtime |
| Spacing | {{SPACING_SCALE}} | directional insets only |
| Radii and elevation | {{RADII_ELEVATION}} | {{NOTES}} |
| Motion | {{DURATIONS_AND_CURVES}} | every use has a reduce-motion variant |

## Components

One per file, with states, light and dark, and both directions, shown in a debug-only gallery.

| Component | States | Notes |
|---|---|---|
| {{COMPONENT_A}} | {{STATES}} | {{NOTES}} |
| {{COMPONENT_B}} | {{STATES}} | {{NOTES}} |

## Motion

- Durations and curves come from the motion tokens, calm and precise.
- Reduce-motion: one switch honouring the system setting; replace movement with a short fade or none.
- Animate transform and opacity; avoid layout-affecting properties.
- No motion that carries meaning alone.

## Layout by width class

| Class | Width | Layout rule |
|---|---|---|
| Compact | under 600 | {{RULE}} |
| Medium | 600 to 1023 | {{RULE}} |
| Expanded | 1024 and up | {{RULE}} |

Layout follows window width, not device type. Touch targets and spacing are never scaled down.

## Languages, direction and numbers

- Languages: {{LANGUAGES}}. Strings live in resource files for each language, added in the same change.
- Right-to-left from day 0: directional properties only, no left or right literals.
- Numbers display through one formatter (Arabic-Indic digits in Arabic); the API always gets Western digits.

## Copy tone

Quiet, courteous, short. Say what happened and what to do next. {{VOICE_EXAMPLES}}<!-- VOICE_EXAMPLES: one good line, one line to avoid -->. Never show raw server text.

## Accessibility

Labels, focus order, {{MIN_TARGET}} touch targets, contrast {{CONTRAST_TARGET}}, text scaling to {{TEXT_SCALE_MAX}}, reduce-motion, screen-reader order checked per screen.

## Review before UI ships

- [ ] Both themes and both directions
- [ ] Each width class
- [ ] Reduce-motion on
- [ ] Largest text size

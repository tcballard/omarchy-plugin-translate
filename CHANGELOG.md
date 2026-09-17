# Changelog

These headings record plugin versions, not Git tags or GitHub releases. As checked
on 17 September 2026, neither tags nor published GitHub releases exist.

## 0.1.1

Listed in the [official Omarchy plugin marketplace](https://omarchyplugins.com/plugin.html?id=io.github.tcballard.bartranslate)
on 16 September 2026. Automated verification applies to snapshot
`74c8881bf96311cda119b2f914f9f14522351fe1` only, not later commits or a
blanket security approval. See [acceptance evidence](docs/verification.md#marketplace-acceptance--16-september-2026).

- Correct short-text automatic detection when Google misclassifies inputs such
  as “Bonjour” as English and returns them unchanged. A bundled local model
  supplies a source hint only when its scores are clearly separated.
- Show the detected language in the source selector after translation.
- Prompt for a manual source language when the provider is uncertain and the
  local model cannot resolve the ambiguity. Preserve explicit source choices.
- Add regression tests for case/punctuation, ambiguous text, explicit-language
  requests, already-English input and successful translations without retries.

## 0.1.0

- Native Omarchy translation panel with searchable languages, paste/copy,
  language swap and keyboard controls.

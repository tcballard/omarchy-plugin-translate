# Changelog

## 0.1.1

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

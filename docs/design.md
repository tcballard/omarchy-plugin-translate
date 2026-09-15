# Native plugin design

- ID: `io.github.tcballard.bartranslate`; kind: `bar-widget`.
- `BarWidget.qml` owns a private `Panel.qml` built on `Ui.Panel` and `Ui.KeyboardPanel`.
- Each bar instance owns its input, selected languages and translation. Requests only happen on explicit Translate; there is no polling or shared background service.
- The native panel follows the host widget’s monitor, bar placement, popup coordination, focus and outside-click dismissal. It uses `qs.Commons` colour/font/spacing/border tokens and `qs.Ui` controls.
- Searchable source/target selectors, language detection, swap, paste and copy. Source/translation remain in memory, not shell.json or a history database. Closing retains text but cancels work; unloading clears state.
- Python receives bounded JSON on stdin; source text is never in child argv. No shell interpolation. The fixed interpreter ignores Python environment/user-site overrides.
- Translation goes only to `https://translate.googleapis.com/translate_a/single`, client `dict-chrome-ex`. This is an unofficial, keyless Google endpoint. It is not an official Cloud Translation API contract. No provider fallback silently resubmits content elsewhere.
- Python bounds input, clipboard and response sizes, validates response shape and uses socket plus whole-operation deadlines. The QML parent has an additional deadline and cancels on close. HTTP rate limits, malformed responses, network failures and oversized inputs become native error messages.
- Clipboard reads are explicit, bounded and cancelled by a helper deadline. Copy passes text through stdin to `wl-copy`.
- Google may process submitted text under its own policies. The plugin has no webview, remote script execution, credential storage, package installation or privileged operations.
- Deterministic preview uses sample French/English text. Portable tests cover URL encoding, segment parsing and invalid/oversized data. Live verification covers actual host loading, translation and dismissal.
- Deferred: persistent language preferences, additional translation providers, speech and history. A multi-monitor host was not available for runtime testing.

# Verification — 15 September 2026

Target: Omarchy source `4ee6d4eeea176b0bf4014ce8b82a148a9433efff`,
Quickshell 0.3.1, live Hyprland desktop at 125% scale. Local source build.

Passed:

- `./tests/run`: portable and installed-host manifest validation, four Python unit tests, Python compilation.
- Toolkit `validate_plugin.py --security .`: valid; expected process/collected-input capabilities require review. Producer-side byte bounds and deadlines are implemented in the helper.
- Actual hosted QML loaded in the existing Omarchy shell. The panel uses the active amber theme, font and popup controls; no GTK/webview or separate application window.
- Searchable language selectors render with French/English selection, input and output are legible and theme-matched, panel anchored to the bar icon.
- Live backend sample and real native-panel Ctrl+Enter: “Bonjour, comment allez-vous ?” → “Good morning, how are you doing ?”. The screenshot in `preview.png` captures the actual response, not a fixture.
- Outside-click dismissal observed; subsequent opens restore the panel. Explicit hide and rescan exercised.
- Fixed offline preview available via the plugin’s `demo` IPC method.

QML lint parsed both files with the actual shell imports. Qt tooling emitted
warnings for dynamic singleton properties and Quickshell’s QProcess enum metadata;
these were not load failures. The live shell log contained no BarTranslate
TypeError/ReferenceError when the final interface was exercised.

Not exercised: multiple physical monitors, speech (not implemented), network
outages/rate limits through the UI, alternate themes. Rate limits were observed
while choosing the endpoint and are handled explicitly. This is an unofficial
Google endpoint and availability is not guaranteed.

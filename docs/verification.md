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

## 0.1.1 automatic detection regression — 16 September 2026

Google returned `en` with confidence `0.7584857` and unchanged text for
`Bonjour` in automatic mode. The new bounded local ELD fallback resolves that
case to French and retries once with `sl=fr`, preserving the original input.
Live result: `Bonjour` → `Good morning`, detected `fr`.

The suite now has 11 passing tests, including the captured failure, case and
punctuation, explicit source preservation, confident English, ambiguous short
text and successful translations without a retry. The ELD model and adapted
code are Apache-2.0 with pinned provenance. The QML source picker displays the
detected name without changing automatic mode, and hides stale detection when
input or languages change. The runtime-testing limitations recorded above still apply.

## Marketplace acceptance — 16 September 2026

Status rechecked on 17 September 2026:

- [Public BarTranslate listing](https://omarchyplugins.com/plugin.html?id=io.github.tcballard.bartranslate): version 0.1.1, available, snapshot verified.
- [Acceptance issue #7192](https://github.com/omacom/omarchy-plugin-marketplace/issues/7192) is closed with `listed` and `approved-and-verified` labels. Its publication comment identifies the verification method as `automated`.
- [Marketplace commit](https://github.com/omacom/omarchy-plugin-marketplace/commit/0d685d01914eb6052e42a1328ca53f171a16b8df) records the listing. The current official catalog records verification of `74c8881bf96311cda119b2f914f9f14522351fe1` on 16 September 2026.
- Repository `main` was still at that snapshot when checked; there were no Git tags or published GitHub releases. The version in the manifest and changelog does not establish a tagged release.

Verification applies only to the recorded snapshot. Automated marketplace checks
are not a security audit, certification, warranty or approval of subsequent
commits. The listing’s installation command clones current upstream source;
it does not pin the verified snapshot.

This documentation update adds no live installation or desktop-test evidence.
The recorded Omarchy revision, Quickshell version and runtime-testing limits
above remain the scope of the compatibility evidence.

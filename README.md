# BarTranslate for Omarchy

[![Built for Omarchy: Plugin](https://raw.githubusercontent.com/tcballard/omarchy-badges/75975e5b5bf75e7ede3764bcd2950046f7abfe2c/badges/v1/omarchy-plugin.svg)](https://github.com/tcballard/omarchy-badges)
[![Omarchy Plugin Marketplace: Available](https://img.shields.io/badge/Omarchy_Plugin_Marketplace-Available-22c55e)](https://omarchyplugins.com/plugin.html?id=io.github.tcballard.bartranslate)

A native translation panel attached to your Omarchy bar. Uses your current theme’s colours, fonts, borders, buttons and searchable language selectors.

![Native BarTranslate panel](preview.png)

Inspired by [Thijmen Dam’s BarTranslate](https://github.com/ThijmenDam/BarTranslate), built with [Build Omarchy Plugins](https://github.com/tcballard/build-omarchy-plugins). The interface is entirely QML inside Omarchy; Google supplies translation data only.

## Use

- Click the translation icon to open or close the panel.
- Type text, select languages, and press **Translate** or **Ctrl+Enter**.
- **Right-click** the icon or press **Paste** to bring in clipboard text. It is sent only when you press Translate.
- Use **Copy** for the translation and the swap button to reverse languages.
- **Escape** or an outside click dismisses the panel and cancels an active request.

Includes language detection and 45 searchable target languages. After translation, the source selector shows the detected language. A bundled local character model checks short text when Google returns it unchanged with low confidence; ambiguous cases ask you to select a source language. Text and translation stay in memory while the widget is loaded; no translation history is written to disk. Your active Omarchy theme controls the panel appearance, including transparency.

Translations require internet access. Clicking Translate sends the entered text to Google’s public translation endpoint. No API key is required. This endpoint is unofficial and can change or rate-limit requests; errors are shown inside the panel. There is no browser/webview, remote page styling, automatic clipboard monitoring, or automatic translation while typing.

## Installation

Requires Omarchy 4/Quattro, Python 3 and `wl-clipboard` (normally installed on Omarchy). No GTK or WebKit dependencies.

Available in the [official Omarchy plugin marketplace](https://omarchyplugins.com/plugin.html?id=io.github.tcballard.bartranslate). Install using the listing’s command:

```bash
omarchy plugin add https://github.com/tcballard/omarchy-plugin-translate.git --enable
```

This command installs the current upstream repository, which may differ from the verified marketplace snapshot.

For local development, with this checkout at `~/Source/omarchy-bartranslate`:

```bash
ln -s "$HOME/Source/omarchy-bartranslate" "$HOME/.config/omarchy/plugins/io.github.tcballard.bartranslate"
omarchy-shell shell rescanPlugins
# Wait for the shell rescan, then:
omarchy plugin enable io.github.tcballard.bartranslate --section right
```

The symlink command refuses an existing destination. During local development, rescan plugins after editing the checkout. The source repository is [tcballard/omarchy-plugin-translate](https://github.com/tcballard/omarchy-plugin-translate).

## Marketplace status

BarTranslate 0.1.1 was listed on 16 September 2026. The marketplace marked snapshot [`74c8881bf96311cda119b2f914f9f14522351fe1`](https://github.com/tcballard/omarchy-plugin-translate/commit/74c8881bf96311cda119b2f914f9f14522351fe1) verified using automated checks. Verification applies only to that snapshot; it is not a security audit or blanket approval of later commits. See the [acceptance issue](https://github.com/omacom/omarchy-plugin-marketplace/issues/7192) and [recorded evidence](docs/verification.md#marketplace-acceptance--16-september-2026).

As checked on 17 September 2026, the repository has no Git tags or published GitHub releases. Marketplace availability and the 0.1.1 manifest/changelog version are separate from a tagged release.

## Commands

```bash
omarchy-shell shell toggle io.github.tcballard.bartranslate
omarchy-shell shell hide io.github.tcballard.bartranslate
omarchy-shell io.github.tcballard.bartranslate clipboard
omarchy-shell io.github.tcballard.bartranslate demo
```

The clipboard command opens and pastes; translation remains explicit. The demo is labelled and contains a fixed sample. Global keybindings are not installed automatically.

## Verification

```bash
./tests/run
omarchy plugin validate .
```

See [verification](docs/verification.md) and [design](docs/design.md). The supplied Workbench definition supports optional project registration and validation.

## Remove

For a normal GitHub installation:

```bash
omarchy plugin remove io.github.tcballard.bartranslate
```

For the local development symlink:

```bash
omarchy plugin disable io.github.tcballard.bartranslate
unlink "$HOME/.config/omarchy/plugins/io.github.tcballard.bartranslate"
omarchy-shell shell rescanPlugins
```

These commands preserve the source checkout. Disabling unloads the widget and its request process. No translation history or browser profile needs cleanup.

GPL-3.0-only. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

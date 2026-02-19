# LuLu-Lockdown

[简体中文](README_zh-Hans.md) | [正體中文](README_zh-Hant.md)

LuLu-Lockdown is a combined firewall platform that builds on LuLu and Lockdown-Mac ideas.

**Maintainer:** `john-f-m`

## Overview

This project extends LuLu with stricter connection decision workflows, silent review workflows, richer traffic visibility, and curated bad-actor feed imports.

## Feature Set

![LuLu-Lockdown](/docs/images/lulu_text.png)

**LuLu-Lockdown** is a privacy-focused fork of the open-source LuLu firewall for macOS. It is designed to proactively block surveillance and tracking while providing high-end network intelligence.

### 🛡️ Why Lockdown?
While the original LuLu is a powerful firewall, **LuLu-Lockdown** adds pre-configured defense layers and advanced visualization, making it the perfect tool for security-conscious users who want to "set it and forget it" without sacrificing deep insight.

### ✨ Key Features
*   **Surveillance Block**: Proactively blocks all traffic to Meta (Facebook/Instagram/WhatsApp) and X (Twitter) using dynamic ASN-based IP ranges.
*   **Advanced Network Intelligence v2**: A premium, high-security dark-themed dashboard featuring:
    *   **Interactive Analytics**: Chart.js-powered insights into your top-talking apps and protocol distributions.
    *   **Dynamic Traffic Map**: Global visualization with animated arcs showing data flow intensity and direction.
    *   **Audit Logging**: A detailed, searchable log of every connection attempt with integrated risk scoring.
*   **Simplified Experience**: Pre-configured rules for standard macOS services and common developer tools.
*   **Open Source**: Transparent, community-driven, and always free.
- `Passive mode`
  - preserved and still available.
  - remains mutually exclusive with `Strict` and `Silent`.

### Pending review workflow

- Review queued connections one-by-one.
- For each connection, choose:
  - `Allow` (creates rule),
  - `Block` (creates rule),
  - `Skip`.

### Traffic telemetry and insights

- Captures connection telemetry including:
  - process name and path,
  - endpoint/IP/host,
  - destination port,
  - protocol,
  - decision and reason,
  - timestamp.
- Includes `Open Traffic Insights` action to generate an interactive report with:
  - protocol graph,
  - top destination port graph,
  - recent connection table,
  - global map markers for IP-based destinations.

### Bad actor feed import

- Added `Import Lockdown-Mac Bad Actor Lists` action.
- Pulls and merges curated Lockdown-Mac feed files into a local block list file.
- Automatically enables LuLu global block-list mode with imported entries.

### Social Media Block

- Added `Social Media Block` functionality.
- Supported platforms:
  - `Block Meta (Facebook, Instagram, WhatsApp)`: Blocks Meta-owned domains and IP prefixes (with CIDR matching).
  - `Block X (Twitter)`: Blocks X-owned domains and IP prefixes (sourced from AS13414, AS35995, and AS63179).
- Maintainable update scripts provided in `MetaBlock/scripts` and `XBlock/scripts` to keep IP ranges current.
- More social media platforms scheduled for upcoming releases.

## Lockdown-Mac integration references

This combined branch draws from publicly available Lockdown-Mac feature concepts and list feeds:

- Repository: <https://github.com/confirmedcode/Lockdown-Mac>
- Block list UI concept: `LockdownMac/BlockListsView.swift`
- Block log concept: `LockdownMac/BlockLogView.swift`
- Metrics concept: `LockdownMac/BlockMetricsView.swift`
- Curated feed files under `Block Lists/`

## GitHub Landing Page

A GitHub Pages landing page is included at:

- `docs/index.html`

To publish on GitHub Pages, set the repository Pages source to:

- Branch: `main` (or your default branch)
- Folder: `/docs`

## Local Build

### Xcode (GUI)
1. Open `lulu.xcworkspace` in Xcode.
2. Build the `LuLu` scheme.

### CLI Build
To build LuLu from the command line:

1. Ensure full **Xcode** is installed and active:
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. Run the build script:
   `./scripts/build_app.sh`

The built `LuLu.app` will be located in the `Release/` directory.

### Create DMG
To create a distributable disk image:

1. Ensure the app is built (see above).
2. Run the packaging script:
   `./scripts/package_dmg.sh`

This will generate a `LuLu_<version>.dmg` in the root directory.

### Post-Build Actions
- Approve required system/network extension permissions on macOS when running the app for the first time.

### Testing without a Developer Account
If you do not have a paid Apple Developer account, you will encounter an **"activation failed"** error when launching your local build. This is because macOS requires a valid **Network Extension entitlement** (granted only to paid developers) to activate a system extension.

To test your local build without a paid account, you must lower the system's security:

1. **Disable SIP**: Boot into Recovery Mode and run `csrutil disable`.
2. **Enable Developer Mode**: Run `systemextensionsctl developer on` in the terminal.
3. **App Location**: Ensure the app is running from `/Applications`.

> [!WARNING]
> Disabling SIP reduces the security of your Mac. This should only be done on a dedicated test machine or if you are fully aware of the implications.

## Notes

- This project currently targets macOS and uses the existing LuLu app/extension architecture.
- Existing rule/profile compatibility is preserved.

## License

This project remains licensed under `GPL-3.0` (see `LICENSE.md`).

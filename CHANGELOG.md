# Changelog

## 2026-02-18

### Added
- First-run choice to keep baseline allowances or initialize from a clean state.
- `Strict interactive mode` to force a decision prompt for new/changed connections.
- `Silent mode` to allow now and queue connections for later allow/block review.
- Connection telemetry capture and export-backed traffic insights workflow.
- Interactive traffic-insight report generation with protocol/port charts and global map plotting.
- Lockdown-style bad actor list import and merge flow for domains/IPs.
- GitHub landing page at `docs/index.html`.

### Changed
- Updated project naming to `LuLu-Lockdown` in user-facing docs and product metadata strings.
- Updated README set (`README.md`, `README_zh-Hans.md`, `README_zh-Hant.md`) with expanded combined feature set.
- Updated maintainer attribution to `john-f-m`.
- Extended app/daemon XPC APIs and rule-handling paths for queued connection review and resolution.

### Removed
- Removed `.github/FUNDING.yml`.
- Removed README references to the old `objective-see.com/products/lulu.html` product URL.

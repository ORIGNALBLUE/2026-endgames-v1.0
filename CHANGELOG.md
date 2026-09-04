# Changelog

## 1.1.1 — 2026-09-05
- Added privacy-aware local session logging.
- Added one-click Support Bundle export for future troubleshooting.
- Support Bundle includes redacted logs, SDK tracker/manifest, settings summary, OS/GPU/driver data, runtime versions and SHA256 hashes.
- Added standalone `Launch_Diagnostics.cmd` for cases where the main UI cannot start.
- No automatic upload or telemetry is performed.

## 1.1.0 — 2026-09-05
- Rebuilt UI around four tabs to reduce clutter.
- Added runtime-selectable localization with 8 language packs.
- Added local runtime version detection for OptiScaler, XeSS/XeFG/XeLL and AMD FidelityFX DLLs.
- Added live GitHub Releases tracker for OptiScaler, Intel XeSS, NVIDIA Streamline and AMD FidelityFX SDK.
- Added 6/12/24-hour in-app scheduled checks and check-on-launch.
- Reworked SDK downloader to fetch latest release assets dynamically instead of hard-coded version URLs.
- Added daily GitHub Actions upstream SDK tracker.
- Kept SDK archives separate from game runtime; no automatic vendor-DLL hot swap.
- Preserved backup/restore and anti-cheat deployment guard.
- Removed pre-bundled SDK archives from the main distribution layout to reduce package clutter.

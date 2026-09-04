# AetherScaler Lifeline 0.2 / 續命版 — Playability Edition

A public-friendly legacy/low-end GPU rescue package built around a simplified OptiScaler deployment flow.

## What changed in 0.2
- 8-language external manager with live language switching.
- Simplified Play / Advanced / Support layout.
- Recommended route uses detected GPU tier + measured pre-FG FPS.
- PublicSummary + PrivateSupport privacy split; nothing uploads automatically.
- GitHub issue workflow for opt-in compatibility reports.
- Lifeline i18n Core patch kit adds a compact multilingual in-game panel and CJK glyph ranges.
- FSR 4.0.2c remains blocked; FSR 4.0.2 is manual experimental only.
- Backup/restore and anti-cheat deployment guard remain enabled.

## Important
The bundled OptiScaler binary is the unmodified upstream-derived runtime supplied to this project. The **native in-game multilingual Lifeline panel requires building the included GPL source patch against OptiScaler**. Until that patched DLL is built, the external Lifeline manager is multilingual while OptiScaler's stock advanced menu remains English.

See `Docs/QUICKSTART_ZH-TW_EN.md` and `Docs/PRIVACY_ZH-TW_EN.md`.

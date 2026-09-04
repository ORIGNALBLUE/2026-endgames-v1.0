# AetherScaler Bridge 1.1.1 / 三芯橋

A compact, multilingual deployment and configuration layer for OptiScaler-based single-player/offline modding workflows.

## Highlights
- Runtime language switcher: 繁體中文 / English / 日本語 / 한국어 / Deutsch / Français / Español / Português (Brasil)
- Simplified 4-tab UI: Home, Advanced, SDK & Updates, Help
- Local DLL version scanner + official SDK release tracker
- Optional 6/12/24-hour in-app update checks
- Official SDK downloads are staged under `SDK_Archives` instead of being injected automatically
- Daily GitHub Actions upstream SDK tracker
- Backup/restore and anti-cheat deployment guard
- Privacy-aware local diagnostics and Support Bundle export

## Start
Run `Launch_AetherScaler.cmd` on Windows 10/11 with PowerShell 5.1+.

If the main UI cannot start, run `Launch_Diagnostics.cmd` to create a standalone support bundle.

## Diagnostics
AetherScaler 1.1.1 can generate `SupportBundles/AetherScaler_Support_*.zip` containing relevant local logs, SDK tracker/manifest, configuration summary, OS/GPU/driver information, runtime DLL versions and SHA256 hashes. User name, user-profile path and selected game folder are redacted from copied text logs. Nothing is uploaded automatically; review the archive before public sharing.

## Update model
The updater uses an **audit-and-stage** design. It checks official GitHub releases for OptiScaler, Intel XeSS, NVIDIA Streamline and AMD FidelityFX. New SDK archives are downloaded into `SDK_Archives`; vendor DLLs are not blindly hot-swapped into a working game installation.

## Safety / Scope
No anti-cheat bypass, DRM bypass, driver-signature bypass, or reverse engineering of vendor binaries is implemented. Intended for offline/single-player/mod-friendly environments.

## Upstream
- OptiScaler: https://github.com/optiscaler/OptiScaler
- Compatibility: https://github.com/optiscaler/OptiScaler/wiki/Compatibility-List
- Intel XeSS: https://github.com/intel/xess
- NVIDIA Streamline: https://github.com/NVIDIA-RTX/Streamline
- AMD FidelityFX SDK: https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK

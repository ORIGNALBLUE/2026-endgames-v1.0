# AetherScaler Bridge 1.1.1 — Manual / 說明書

## 中文
AetherScaler Bridge 是 OptiScaler 0.9.4-based 的部署、設定、版本稽核與診斷管理層，定位於單機、離線或允許 Mod 的遊戲環境。

### 基本流程
1. 執行 `Launch_AetherScaler.cmd`。
2. 在右上/頂部選擇介面語言。
3. 選擇遊戲 EXE 所在資料夾。
4. 選 Hook/Proxy 名稱與快速預設。
5. 需要時到 Advanced 調整 DX11/DX12/Vulkan upscaler、Frame Generation 與 spoofing。
6. 按 Apply；程式會先建立 `.AetherScaler_Backup`。

### SDK 與更新
SDK & Updates 頁會掃描本機 runtime DLL 版本，並透過 GitHub Releases API 比對 OptiScaler、Intel XeSS、NVIDIA Streamline、AMD FidelityFX 的官方最新 release。下載的 SDK 壓縮包放在 `SDK_Archives`，不會自動覆蓋正在使用的遊戲 DLL。

可選擇 6 / 12 / 24 小時自動檢查；GitHub repo 另有每日 SDK Tracker workflow。

### 診斷包
按 **Help → Export diagnostic bundle**，或在 UI 無法啟動時執行 `Launch_Diagnostics.cmd`。

輸出：`SupportBundles/AetherScaler_Support_YYYYMMDD-HHMMSS.zip`

內容可能包含：
- AetherScaler launcher/session logs
- OptiScaler.log / fakenvapi.log / dlssg_to_fsr3.log
- OptiScaler.ini 設定副本
- sdk_tracker.json / sdk_manifest.json / settings.json
- Windows / CPU / GPU / driver 基本資訊
- 已部署 runtime DLL 的版本、大小與 SHA256

診斷包只在本機產生，不會自動上傳。文字紀錄會遮蔽 Windows 使用者名稱、USERPROFILE 與所選遊戲完整路徑；公開分享前仍應自行檢查。

## English
AetherScaler Bridge is a deployment, configuration, SDK-audit and diagnostics layer built around an OptiScaler 0.9.4 baseline. It is intended for offline, single-player and mod-friendly environments.

### Basic workflow
1. Run `Launch_AetherScaler.cmd`.
2. Select the UI language.
3. Choose the folder containing the game executable.
4. Select a Hook/Proxy name and quick preset.
5. Use Advanced for DX11/DX12/Vulkan upscalers, Frame Generation and spoofing overrides.
6. Press Apply. A `.AetherScaler_Backup` is created first.

### SDK & updates
The SDK & Updates page scans local runtime DLL versions and compares them with the latest official releases of OptiScaler, Intel XeSS, NVIDIA Streamline and AMD FidelityFX. SDK archives are staged under `SDK_Archives`; they are not blindly hot-swapped into working game folders.

### Diagnostics
Use **Help → Export diagnostic bundle**, or run `Launch_Diagnostics.cmd` if the UI itself cannot start. The generated ZIP is local-only and includes relevant logs, SDK state, configuration summary, OS/GPU/driver data and runtime SHA256 hashes with basic path redaction.

## Safety
AetherScaler does not implement anti-cheat bypass, DRM bypass, driver-signature bypass or reverse engineering of vendor binaries.

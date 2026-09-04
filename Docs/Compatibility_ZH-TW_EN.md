# Compatibility / 相容性

Canonical upstream list / 官方動態清單:
https://github.com/optiscaler/OptiScaler/wiki/Compatibility-List

## 中文
AetherScaler 不把相容性硬寫死成封閉白名單。原則上，能提供 DLSS 2+、FSR2+ 或 XeSS 類 temporal upscaling 輸入的遊戲，通常才有條件被 OptiScaler/AetherScaler 轉接；實際結果仍取決於遊戲 API、Hook 點、Streamline/NGX/FSR/XeSS 實作、Frame Generation 路徑與遊戲特定修正。

### 主要分類
- **Working**：已有玩家或 upstream 驗證可運作。
- **OptiPatcher Supported**：可能需要 OptiPatcher 或特定 Hook/修正。
- **Single-OS / API-specific**：只在特定 Windows/Wine/API 條件下成立。
- **Not working / blocked**：已知無法正常工作，或存在反作弊/架構限制。

### 重要限制
- Anti-cheat 遊戲不應使用自動 DLL proxy 部署；AetherScaler 遇到常見反作弊標記會阻止自動部署。
- Vulkan、DX11On12、FSR FG、XeFG、DLSSG/Streamline 的組合不是互相等價，應以個別遊戲測試為準。
- SDK「有新版」不代表可直接替換 runtime DLL；AetherScaler 採 audit-and-stage 模式，先下載與稽核，再人工套用。

## English
AetherScaler does not freeze compatibility into a closed whitelist. In general, games that expose DLSS 2+, FSR2+ or XeSS-style temporal-upscaling inputs are the strongest candidates, but real compatibility still depends on the rendering API, hook path, Streamline/NGX/FSR/XeSS integration, Frame Generation path and game-specific workarounds.

### Categories
- **Working** — verified by upstream/community reports.
- **OptiPatcher Supported** — may require OptiPatcher or a specific hook/workaround.
- **Single-OS / API-specific** — only valid under particular Windows/Wine/API conditions.
- **Not working / blocked** — known failure or anti-cheat/architecture limitation.

Always treat the upstream OptiScaler Compatibility List as the live source of truth.

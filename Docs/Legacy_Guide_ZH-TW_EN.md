# AetherScaler Lifeline — Legacy GPU Guide / 舊卡續命指南

## 中文
Lifeline 的目標是把舊卡從「跑不動」推到「可玩」，而不是讓所有 GPU 都強制使用同一個 ML 模型。

### 路線
1. **RTX 20/30**：優先 DLSS Super Resolution。這兩代有 Tensor Core，因此不應被當成純無 AI 卡。Frame Generation 預設關閉，必要時使用 analytical FSR FG 或相容 XeSS-FG。
2. **RX 6000 / RDNA2**：預設 FSR 3.1。XeSS 作第二路徑。FSR 4.0.2 僅接受使用者自行提供的 experimental runtime；不提供 4.0.2c。
3. **RX 5000 / RDNA1**：FSR 3.1 為主。XeSS 僅在實際能力/驅動路徑通過時使用。FG 預設關閉。
4. **GTX 16/10**：FSR 3.1 為主。GTX 10 預設完全不開 FG。

### FG 門檻
- <30 FPS：禁止 FG。
- 30–39 FPS：只升頻。
- 40–54 FPS：FG 實驗區，優先改善畫質設定與升頻比例。
- >=55/60 FPS：才考慮 analytical FSR FG；仍以幀時間穩定為優先。

### FSR 4.0.2 Policy
Lifeline 不下載、不附帶、不推薦 FSR 4.0.2c。外部 4.0.2 路徑會留下版本、簽章與 SHA256 日誌，失敗即回退 FSR 3.1/XeSS/DLSS。

## English
Lifeline targets playability first. It uses hardware-tier routing instead of forcing one ML upscaler onto every old GPU. Frame generation is gated by measured pre-FG frame rate, and FSR 4.0.2c is excluded by policy.

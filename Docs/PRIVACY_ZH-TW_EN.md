# Lifeline Privacy / 隱私設計

## 中文
Lifeline 0.2 **不會自動上傳任何資料**。

`PublicSummary_*.json` 是為 GitHub 公開回報設計，只包含：Lifeline 版本、語言、GPU 型號、驅動版本、VRAM 區間、Windows 版本、升頻/FG 狀態與 runtime 版本。它不收集使用者名稱、完整路徑、電腦名稱、IP、MAC、硬體序號、Machine UUID、瀏覽器資料或文件。

`PrivateSupport_*.zip` 會包含較完整的 OptiScaler/Lifeline log 與 INI，但文字中的使用者/電腦名稱、選定遊戲路徑、IPv4 與 MAC-like 字串會先遮蔽。它只留在本機，除非使用者主動分享。

GitHub Issue 是公開且會顯示提交者的 GitHub 帳號，因此不是匿名 telemetry。它只適合作為 opt-in 的公開相容性資料庫。若未來需要真正的大規模匿名統計，建議另外架設只接受 allowlist schema、無 cookie、短期/不保存 IP 的 serverless collector。

## English
Lifeline 0.2 never uploads diagnostics automatically. PublicSummary is a strict allow-list report. PrivateSupport remains local until the user chooses to share it. GitHub issues are public and tied to the submitter account, so GitHub is used as an opt-in compatibility/report database rather than anonymous telemetry.

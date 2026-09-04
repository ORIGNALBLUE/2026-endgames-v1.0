# Lifeline i18n Core Patch Kit

This kit patches the GPL OptiScaler source, not the proprietary vendor SDK DLLs. It adds a compact multilingual in-game Lifeline panel and selects CJK ImGui glyph ranges when a custom font is configured.

Languages: zh-TW, en-US, ja-JP, ko-KR, de-DE, fr-FR, es-ES, pt-BR.

The stock OptiScaler advanced menu remains upstream English. This deliberately minimizes the patch surface. The Lifeline manager writes `LifelineLanguage.txt` and a suitable Windows `TTFFontPath`.

Build: use the included GitHub Actions workflow or clone OptiScaler with submodules, run `Apply-Lifeline-I18n.ps1 -SourceRoot <clone>`, then build Release with MSBuild.

# Third-party notices / 第三方授權說明

AetherScaler Bridge 1.1.1 is a configuration, deployment, update-audit and diagnostics wrapper. Third-party runtimes remain under their original licenses.

- **OptiScaler** — GPLv3. Source: https://github.com/optiscaler/OptiScaler . AetherScaler uses an OptiScaler 0.9.4-final baseline for its runtime package. Corresponding upstream source and GPL notices must remain available when redistributing that runtime.
- **Intel XeSS SDK** — vendor binary terms apply. AetherScaler does not reverse engineer or modify XeSS binaries; official SDK packages are staged separately for audit/integration.
- **AMD FidelityFX SDK** — AMD licensing terms apply to the corresponding runtime and SDK files. Official SDK packages are staged separately.
- **Microsoft DirectX** — system/distributable components remain governed by Microsoft terms; AetherScaler does not treat them as its own code.
- **NVIDIA Streamline** — not blindly bundled or hot-swapped by the updater; the official package can be staged under `SDK_Archives` for compatibility work.

The full distributable package should retain the vendor license files under `Licenses/`.

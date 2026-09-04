# AetherScaler Lifeline 0.1 / 續命版

Legacy-GPU rescue branch of AetherScaler. Target: make older GPUs playable before chasing maximum image quality.

## Target hardware
- NVIDIA RTX 20 / 30 series
- AMD Radeon RX 6000 (RDNA2)
- AMD Radeon RX 5000 (RDNA1)
- GeForce GTX 16 / 10 and other compatible SM6.x GPUs

## Routing policy
- RTX 20/30: DLSS SR first, XeSS/FSR 3.1 fallback.
- RX 6000: FSR 3.1 first, XeSS fallback, external FSR 4.0.2 optional.
- RX 5000 / GTX: FSR 3.1 first, XeSS only when the runtime path succeeds.
- FG is OFF by default and gated by measured pre-FG FPS.
- FSR 4.0.2c is explicitly excluded.

## Important
The included ASR-Lite HLSL file is a custom spatial fallback prototype only; it is not yet connected to the interception runtime.

Use only in offline/single-player/mod-friendly games. No anti-cheat or DRM bypass is implemented.

# Third-party notices

AutonoMatte model ağırlıklarını kaynak arşivine gömmez. Modeller resmi upstream kaynaklardan indirilir ve `models_cache` altında tutulur.

- **BEN2 Base** — PramaLLC/BEN2 — upstream model kartında MIT.
- **BiRefNet ailesi** — ZhengPeng7/BiRefNet — upstream model kartlarında MIT.
- **rembg** — danielgatis/rembg — uygulama MIT; rembg üzerinden indirilen her modelin ağırlık lisansı ayrı olarak upstream kaynağından doğrulanmalıdır.
- **FFmpeg** — temel video düzenleme için harici çalıştırılabilir dosya; FFmpeg kendi lisans koşullarına tabidir.
- **PyTorch, Transformers, ONNX Runtime, NumPy, SciPy, Pillow, Pillow-HEIF, FastAPI ve Uvicorn** kendi lisansları altında kullanılır.

BRIA RMBG-2.0 varsayılan model değildir ve ticari olmayan ağırlık koşulları nedeniyle otomatik model planına eklenmemiştir.

Ticari dağıtımdan önce model manifestindeki `license` alanları upstream sürümle yeniden doğrulanmalıdır. `upstream-defined` değeri, lisansın AutonoMatte tarafından genellenmediği anlamına gelir.

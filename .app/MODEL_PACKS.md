# Model Packs

Model ağırlıkları Git reposuna gömülmez. Manifest `src/autonomatte/models/manifest.json` içinde tutulur; ağırlıklar resmi Hugging Face/rembg kaynaklarından cache'e alınır.

## Komutlar

```bash
autonomatte-models --cache models_cache plan
autonomatte-models --cache models_cache list
autonomatte-models --cache models_cache migrate --project-root .
autonomatte-models --cache models_cache prefetch --recommended --limit 2
```

## NVIDIA

```bash
python -m pip install -e '.[birefnet,formats]'
python -m pip install 'git+https://github.com/PramaLLC/BEN2.git'
```

## AMD Windows

```bash
python -m pip install -e '.[rembg-dml,formats]'
```

## AMD Linux ROCm

```bash
python -m pip install -e '.[rembg-rocm,formats]'
```

## Apple Silicon

```bash
python -m pip install torch torchvision
python -m pip install -e '.[birefnet,formats]'
```

## CPU

```bash
python -m pip install -e '.[rembg-cpu,formats]'
```

Anime/sticker/düz/checkerboard ve mevcut-alpha yolları AI modeli olmadan çalışabilir.

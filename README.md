# AutonoMatte Studio

**Profesyonel, yerel, otonom arka plan silme ve temel medya düzenleme uygulaması.**

## Tek çalıştırma dosyası

Windows kullanıcısı yalnızca şuna çift tıklar:

```text
AutonoMatte.bat
```

Başka bir kurulum, başlatma veya model dosyasına tıklanmaz. Aynı dosya:

- Python yoksa kurmayı dener,
- uygun NVIDIA / AMD / CPU altyapısını seçer,
- eski model cache'lerini `.models` klasörüne taşır,
- model yoksa donanıma uygun modelleri indirir,
- web arayüzünü açar.

## GitHub repository adı

```text
AutonoMatte-Studio
```

Ürün görünen adı:

```text
AutonoMatte Studio
```

## Repository düzeni

```text
AutonoMatte-Studio/
├── AutonoMatte.bat        # Kullanıcının çift tıklayacağı TEK dosya
├── .app/                  # Uygulama kaynak kodu
├── .models/               # Taşınabilir model cache'i
├── .github/               # CI
├── .gitattributes         # Git LFS model kuralları
├── README.md
└── LICENSE
```

## Modelleri GitHub paketine dahil etme

Bu işlem için de ikinci bir launcher yoktur. Aynı dosyayı komut satırından bir kez şu modda çalıştırın:

```powershell
.\AutonoMatte.bat --prepare-github
```

Bu mod:

1. Eski AutonoMatte / Hugging Face / rembg cache'lerini `.models` içine taşır.
2. Evrensel model paketini indirmeyi dener.
3. `MODEL_INVENTORY.json` oluşturur.
4. Git LFS model uzantılarını hazırlar.

Ardından GitHub Desktop veya `git + Git LFS` ile repository'yi yükleyebilirsiniz.

## GitHub yükleme

```powershell
git init
git lfs install
git add .
git commit -m "Initial AutonoMatte Studio release"
git branch -M main
git remote add origin https://github.com/Naveax/AutonoMatte-Studio.git
git push -u origin main
```

Büyük modeller için normal Git yerine Git LFS kullanılmalıdır. İsterseniz modelleri repository geçmişine koymak yerine GitHub Releases altında da yayınlayabilirsiniz.

## Yardımcı modlar

```powershell
.\AutonoMatte.bat --doctor
.\AutonoMatte.bat --reset-runtime
.\AutonoMatte.bat --prepare-github
```

Bunların tamamı aynı tek launcher dosyası üzerinden çalışır.

## Desteklenen sistemler

- Windows 10 / 11
- NVIDIA CUDA
- AMD DirectML
- CPU fallback
- Düşük kaynak modu
- Model cache migration
- Çoklu görsel işleme
- Yüksek çözünürlük
- PNG / WebP / TIFF / JPG ve desteklenen ek codec'ler
- Temel görsel ve video düzenleme

## Lisans

Uygulama kodu MIT lisanslıdır. Dahil edilen üçüncü taraf modeller kendi upstream lisanslarına tabidir. Model paketini herkese açık yayınlamadan önce `.app/THIRD_PARTY_NOTICES.md` ve model kartlarını kontrol edin.

# Roadmap

## P0–P1 — Tamamlandı

- Platform ve donanım profili
- Model manifesti/yöneticisi
- Otonom planlayıcı
- Kalıcı batch kuyruğu
- Çok formatlı export
- Temel görsel/video edit altyapısı
- Sistem doktoru

## P2-A — Kalite çekirdeği tamamlandı

- Semantik subject/component selection
- Çoklu maske hipotezi ve consensus
- Aday maske image-aware puanlama
- Saç/tüy/ince çizgi belirsizlik haritası
- Modeller arası disagreement haritası
- Orijinal çözünürlükte lokal retry
- Yarı saydam alpha consensus koruması
- Foreground color decontamination
- Bellek kontrollü sıralı model orchestration

## P2-B — Materyal uzmanları ve benchmark altyapısı tamamlandı

- Saç/tüy, yarı saydam, ürün, çizim ve karma materyal uzman router'ı
- Renk olasılığına dayalı saç/tüy boşluk temizliği
- Cam, tül, duman ve motion blur için guided partial-alpha koruması
- Ürün kenarı snapping ve çizim lineart koruması
- Uzman self-rejection güvenlik kapısı
- Otomatik dataset kalibrasyonu
- MAE, MSE, SAD, IoU, precision/recall/F1, gradient error ve boundary F1
- CI başarısızlık exit code'u ve ayarlanabilir kalite kapıları

## P2-C — Gerçek veri kalibrasyonu ve rakip benchmarkı

- Lisansı uygun gerçek ground-truth portre/hayvan/ürün/transparency setleri
- Donanım bazlı süre, VRAM ve RAM benchmarkı
- Remove.bg, Photoshop ve açık kaynak modellerle kontrollü aynı-veri karşılaştırması
- Dataset türüne göre model ağırlıklandırma kalibrasyonu
- Connectivity error ve trimap bölgesel metrikler
- Zor örnek koleksiyonu ve sürekli regresyon dashboard'u

## P3 — Profesyonel edit UX

- Canvas tabanlı önce/sonra
- Keep/erase/refine fırçaları
- Görsel crop seçimi
- Katmanlar, gölge ve outline önizleme
- Video timeline ve waveform
- Undo/redo ve proje kaydı

## P4 — Ürün güvenilirliği

- İmzalı model manifesti
- SHA-256 model doğrulama
- İndirme devam ettirme
- Otomatik güncelleme
- Crash dump ve yerel log görüntüleyici
- Platform installer/portable binary

## P5 — Release

- Donanım matrisi
- Uzun süreli batch stress test
- Release candidate
- Reproducible build

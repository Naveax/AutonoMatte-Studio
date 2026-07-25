# Architecture

## İşlem sırası

1. Dosya ve codec doğrulaması
2. EXIF ve alpha okuma
3. İçerik sinyali analizi
4. Donanım profili
5. Otonom processing plan
6. Native-alpha / hybrid-flat / AI-matting motoru
7. P2 aday model üretimi
8. Image-aware aday puanlama
9. Consensus ve semantic component selection
10. Disagreement + detail error map
11. Native-resolution lokal onarım
12. Edge color decontamination
13. Edit katmanı
14. Çok formatlı export
15. JSON raporu ve batch queue commit

## P2 kalite motoru

`quality_engine.py` ağır modelleri sırayla çalıştırır. Aday maskeler tam kaynak çözünürlüğünde çoğaltılmaz; kontrollü çalışma çözünürlüğünde tutulur. Consensus tamamlandıktan sonra tek final alpha kaynak boyutuna yükseltilir. Yalnız hata haritasındaki en yüksek öncelikli tile'lar native çözünürlükte yeniden işlenir.

Aday puanı şu sinyalleri birleştirir:

- yapısal alpha kalitesi
- görüntü kenarıyla maske kenarı uyumu
- subject iç bölgesinin opaklık bütünlüğü
- parlak foreground bölgelerinin korunması
- görüntü sınırındaki arka plan temizliği

Consensus kuralları:

- çoğunluk foreground ise güçlü foreground korunur
- çoğunluk background ise kalıntı bastırılır
- modeller benzer kısmi alpha veriyorsa cam/tül/duman/saç gibi yarı saydamlık korunur
- modeller ayrışıyorsa bölge lokal retry kuyruğuna girer

## Çekirdek modüller

- `content_analysis.py`: içerik yönlendirmesi
- `flat_extractor.py`: düz/dama/anime çıkarımı
- `planner.py`: içerik + donanım + manifest planı
- `quality_engine.py`: P2 candidate/consensus/local repair
- `edge_decontamination.py`: kenar renk bulaşması temizliği
- `hardware.py`: platform ve kaynak profili
- `model_manifest.py`: model sözleşmesi
- `model_manager.py`: cache, migration, inventory, prefetch
- `backends/router.py`: lazy loading ve runtime fallback
- `pipeline.py`: uçtan uca alpha üretimi
- `exporters.py`: PNG/WebP/TIFF/JPG
- `job_queue.py`: kalıcı ve kurtarılabilir batch
- `image_editor.py`: temel görsel düzenleme
- `media_editor.py`: FFmpeg video düzenleme
- `doctor.py`: kurulum ve sistem kontrolü

## Tasarım ilkeleri

- Aynı anda tek ağır model bellekte tutulur.
- Çoklu model kalite artışı için modeller paralel değil sıralı çalıştırılır.
- Büyük görüntülerde aday maskeler çalışma çözünürlüğünde tutulur.
- Düşük donanımda aday sayısı ve lokal onarım sayısı azaltılır.
- Exact RGB gerekli olduğunda `--preserve-rgb` kullanılır.
- Varsayılan profesyonel mod yalnız semi-transparent kenarlarda renk decontamination uygular.
- Batch sonucu yalnız dosya yazımı tamamlandıktan sonra `completed` olur.

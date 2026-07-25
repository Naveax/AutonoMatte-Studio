# P2 Quality Engine

## Amaç

Tek bir modelin maskesini doğrudan kabul etmek yerine farklı güçlü modellerin hipotezlerini karşılaştırmak, en güvenilir ortak alpha'yı üretmek ve yalnız hatalı bölgeleri yüksek çözünürlükte yeniden işlemektir.

## Profiller

| Profil | Aday sayısı | Native repair tile üst sınırı |
|---|---:|---:|
| Eco / Fast | 1 | 0 |
| Balanced düşük kaynak | 2 | 5 |
| Maximum düşük kaynak | 2 | 5 |
| Balanced normal | 3'e kadar | yapılandırılabilir |
| Maximum normal | 3'e kadar | varsayılan 12 |

## CLI

```bash
autonomatte input.jpg output.png --quality maximum --candidate-models 3 --repair-tiles 12
```

Tek model karşılaştırması:

```bash
autonomatte input.jpg output.png --single-model
```

RGB piksellerine kesinlikle dokunmamak için:

```bash
autonomatte input.jpg output.png --preserve-rgb
```

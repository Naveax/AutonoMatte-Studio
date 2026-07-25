# P2-B Specialist Refinement and Benchmark Gates

AutonoMatte 0.6.0 adds a material-aware stage after the P2 multi-model consensus.
The stage is conservative and can reject its own output when the foreground area
changes beyond safety limits.

## Specialist profiles

- `hair_fur`: nearest foreground/background colour likelihood, strand retention,
  and removal of background slots between hair or fur structures.
- `translucent`: guided alpha filtering that preserves partial transparency for
  glass, smoke, veils, motion blur and soft edges.
- `product`: guided edge snapping and controlled alpha sharpening for rigid objects.
- `illustration`: line-art retention and colour-likelihood cleanup.
- `mixed`: a conservative combination of hair/fur and translucent refinement.

The automatic material analyser records all profile scores in every processing
report. A profile can also be forced through the CLI or web interface.

## Ground-truth benchmark layout

```text
DATASET/
  images/
    sample_001.jpg
  masks/
    sample_001.png
```

Run the full pipeline and enforce quality gates:

```bash
autonomatte-benchmark DATASET --output benchmark_run \
  --quality maximum --min-iou 0.94 --min-boundary-f1 0.88 --max-mae 0.035
```

Metrics:

- MAE and MSE
- SAD
- foreground IoU
- precision, recall and F1
- alpha-gradient error
- boundary F1 with a three-pixel tolerance

The command exits with code `2` when a gate fails or a sample cannot be processed.
This makes it usable in CI.

## Specialist calibration layout

Calibration operates on existing initial masks so expensive AI models do not need
to be rerun for every strength candidate.

```text
DATASET/
  images/
  initial_masks/
  masks/
```

```bash
autonomatte-calibrate DATASET --output my_calibration.json
```

Use the generated profile:

```bash
autonomatte input.jpg output.png --calibration my_calibration.json
```

The built-in calibration is intentionally conservative. Dataset-specific
calibration is recommended before claiming benchmark superiority for a particular
domain.

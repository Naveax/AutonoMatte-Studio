# Test Report — AutonoMatte 0.6.0

## Automated test suite

- **44/44 tests passed**
- Existing-alpha preservation
- Flat/checkerboard/illustration extraction
- Multi-model consensus and native repair
- Edge colour decontamination
- Hardware planning, model manifest and persistent queue
- Multi-format export and basic image/video tooling
- Hair/fur gap cleanup and strand retention
- Partial-alpha preservation for translucent material
- Forced specialist profiles and pipeline reporting
- Benchmark metric correctness
- Benchmark CI gate execution
- Calibration profile loading and calibration CLI execution

## User-image regression

The 20 supplied anime/chibi/sticker images were reprocessed:

- Processed: **20/20**
- Errors: **0**
- Resolution preserved: **20/20**
- Correct flat/checkerboard/illustration route: **20/20**
- Maximum border alpha mean: **0.0**
- Heavy photo-model loads: **0/20**

## Hardware limitation

The execution environment does not contain an RTX 3080, RX570 DirectML device,
ROCm GPU or Apple MPS device. Real-model speed and quality claims on those devices
remain unverified here. The CPU-safe logic, routing, specialist algorithms,
benchmark tools, packaging and non-GPU regression suite were verified.

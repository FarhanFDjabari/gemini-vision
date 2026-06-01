# Gemini Vision

## Introduction

Gemini Vision is a fun project to explore on-device generative AI. It is a mobile
app that lets the user take a picture and get a spoken-friendly description of the
image — powered entirely by an **on-device Gemma LiteRT-LM model** through the
[`flutter_gemma`](https://pub.dev/packages/flutter_gemma) plugin. After a one-time
model download, all inference runs locally with no network round-trip.

## Features

- Describe a captured image using an on-device Gemma 4 (E2B) LiteRT-LM model
- One-time model download on first launch with live progress and retry
- Text-to-speech feature to read the description of the image **[Work in progress]**

## How it works

1. On launch the app checks whether the model is already installed.
2. If it is missing, a setup screen shows **download progress** while the
   `.litertlm` weights are fetched (with retry on failure).
3. Once the model is downloaded and loaded, the camera screen is shown and every
   capture is captioned by the local model.

```text
launch ─▶ ModelSetupScreen ─┬─ installed ──────────────▶ load ─▶ CaptureVisionScreen
                            └─ missing ─▶ download (progress) ─▶ load ─▶ CaptureVisionScreen
```

## Architecture

The app follows a small layered structure. The on-device model lifecycle is hidden
behind the `InferenceService` interface so presentation and data code depend on a
plain Dart contract that is trivial to fake in tests — the native plugin is only
referenced by a single implementation.

```text
lib/
├── main.dart                         # Bootstraps FlutterGemma + ProviderScope, gates on ModelSetupScreen
├── env.dart                          # --dart-define config (HUGGINGFACE_TOKEN, MODEL_URL)
├── core/
│   ├── config/
│   │   └── model_config.dart         # Model URL, derived filename, maxTokens, vision prompt
│   ├── ai/
│   │   ├── inference_service.dart    # InferenceService interface + InferenceException
│   │   └── gemma_inference_service.dart  # flutter_gemma implementation + Riverpod provider
│   ├── data/
│   │   └── datasource/
│   │       └── vision_datasource.dart    # VisionDataSource + LiteRtVisionDataSource
│   ├── repository/
│   │   └── app_repository.dart       # Resizes the frame, delegates captioning to the data source
│   └── util/                         # Provider observer, debug helpers
└── presentation/
    ├── model_setup_screen.dart       # Startup gate: checking / downloading / ready / error
    ├── capture_vision_screen.dart    # Camera preview + capture
    ├── providers/                    # Riverpod notifiers + sealed states
    │   ├── model_setup_provider.dart / model_setup_state.dart
    │   └── capture_vision_provider.dart / capture_vision_state.dart
    └── widgets/                      # Camera preview widget
```

**Request flow for a capture**

```text
CaptureVisionScreen
  ▶ CaptureVisionNotifier.captureVision(XFile)
    ▶ AppRepository.getCaption        # decode + resize to PNG bytes in an isolate
      ▶ LiteRtVisionDataSource
        ▶ GemmaInferenceService.generateCaption   # multimodal LiteRT-LM session
```

State management is [Riverpod](https://riverpod.dev). Each async stage is modelled
with a sealed state (`ModelSetupState`, `CaptureVisionState`) and consumed with
exhaustive `switch` expressions.

## Requirements

- [Flutter](https://flutter.dev/docs/get-started/install) `3.41.x` (pinned via `.fvmrc`)
- Android API 26+ or iOS 16+
- A device with enough storage/RAM for the model (the E2B weights are several GB)

## Installation

```bash
git clone https://github.com/FarhanFDjabari/gemini-vision.git
cd gemini-vision
flutter pub get
```

## Usage

The app downloads a **public** Gemma LiteRT-LM model from Hugging Face on first
launch, so no token is required — just run:

```bash
flutter run
```

To point the app at gated or self-hosted weights, both of these can be supplied at
build time (both optional):

```bash
flutter run \
  --dart-define=MODEL_URL=https://huggingface.co/.../model.litertlm \
  --dart-define=HUGGINGFACE_TOKEN=hf_your_token
```

Without them the app uses the default public model URL defined in
[`lib/core/config/model_config.dart`](lib/core/config/model_config.dart).

## Testing

```bash
flutter test
```

Unit tests use hand-written fakes against the `InferenceService` / `VisionDataSource`
contracts, covering config resolution, image processing/delegation, and the capture
and model-setup state transitions.

## CI / CD

GitHub Actions workflows live in [`.github/workflows`](.github/workflows):

- **CI** (`ci.yml`) — runs on every pull request to `main`: format check,
  `flutter analyze`, and `flutter test`.
- **Release** (`release.yml`) — runs when a `v*` tag is pushed to `main`: builds a
  release APK, uploads it as a workflow artifact, and attaches it to a GitHub
  Release.

To cut a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

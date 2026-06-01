# Gemini Vision

## Introduction

Gemini Vision is a fun project to explore on-device generative AI. It is a mobile
app that lets the user take a picture and get a spoken-friendly description of the
image — now powered entirely by an **on-device Gemma LiteRT-LM model** via the
[`flutter_gemma`](https://pub.dev/packages/flutter_gemma) plugin, so inference runs
locally with no network round-trip after the initial model download.

## Features

- Describe a captured image using an on-device Gemma 4 (E2B) LiteRT-LM model
- One-time model download on first launch with live progress and retry
- Text-to-speech feature to read the description of the image **[Work in progress]**

## How it works

1. On launch the app checks whether the model is already present on the device.
2. If it is missing, a setup screen shows download progress while the
   `.litertlm` weights are fetched.
3. Once the model is downloaded and loaded, the camera screen is shown and every
   capture is captioned by the local model.

The on-device lifecycle (install check, download, load, inference) lives behind
`InferenceService` (`lib/core/ai/`), keeping the rest of the app testable without
the native plugin.

## Requirements

- [Flutter](https://flutter.dev/docs/get-started/install) (3.41.x)
- Android API 26+ or iOS 16+
- A device with enough storage/RAM for the model (the E2B weights are several GB)

## Installation

```bash
git clone https://github.com/FarhanFDjabari/gemini-vision.git
```

## Usage

The model is downloaded from Hugging Face. If you are using gated weights, supply a
[Hugging Face access token](https://huggingface.co/settings/tokens). You can also
override the download URL (for a self-hosted mirror or a different quantization):

```bash
flutter run \
  --dart-define=HUGGINGFACE_TOKEN=hf_your_token \
  --dart-define=MODEL_URL=https://huggingface.co/.../model.litertlm
```

Both defines are optional — without them the app uses the default public model URL
defined in `lib/core/config/model_config.dart` and an unauthenticated download.

## Testing

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Gemini Vision

## Introduction

Gemini Vision is fun project that I started to learn more about Google Gemini API and how to use it to create a simple image recognition system.

This project is basically a mobile app that allows the user to take a picture and get the description of the image powered by Gemini API.

## Features

- Get the description of the image using Gemini API
- Text-to-speech feature to read the description of the image **[Work in progress]**

## Requirements

To run the project, you need to have the following tools installed:

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Google Gemini API Key](https://ai.google.dev/gemini-api/docs/vision?lang=rest#set-up-project-and-key)

## Installation

You can clone the repository using the following command:

```bash
git clone https://github.com/FarhanFDjabari/gemini-vision.git
```

## Usage

Before run the project, you need to create a `.env` file in the root of the project with the following content:

```json
{"gemini_api_key": YOUR_GEMINI_API_KEY}
```

You can get your Gemini API key by following the instructions in the [official documentation](https://ai.google.dev/gemini-api/docs/vision?lang=rest#set-up-project-and-key).

To use the project, you can run the following command:

```bash
flutter run app --dart-define-from-file=.env
```

Please note that you need to provide .env as --dart-define-from-file argument to make sure that the environment variables are loaded correctly.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

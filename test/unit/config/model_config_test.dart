import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_vision/core/config/model_config.dart';

void main() {
  group('ModelConfig', () {
    test('falls back to the default download URL when unset', () {
      expect(ModelConfig.downloadUrl, ModelConfig.defaultDownloadUrl);
    });

    test('derives the filename from the download URL basename', () {
      expect(
        ModelConfig.fileName,
        Uri.parse(ModelConfig.downloadUrl).pathSegments.last,
      );
      expect(ModelConfig.fileName.endsWith('.litertlm'), isTrue);
    });
  });
}

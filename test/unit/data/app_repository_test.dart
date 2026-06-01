import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemini_vision/core/data/datasource/vision_datasource.dart';
import 'package:gemini_vision/core/repository/app_repository.dart';
import 'package:image/image.dart' as img;

class _RecordingDataSource implements VisionDataSource {
  Uint8List? receivedBytes;

  @override
  Future<String> getCaption(Uint8List imageBytes) async {
    receivedBytes = imageBytes;
    return 'recorded caption';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppRepository', () {
    test('processes the image and delegates to the data source', () async {
      final pngBytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 8, height: 8)),
      );
      final dataSource = _RecordingDataSource();
      final repository = AppRepository(datasource: dataSource);

      final caption = await repository.getCaption(
        XFile.fromData(pngBytes, name: 'frame.png'),
      );

      expect(caption, 'recorded caption');
      expect(dataSource.receivedBytes, isNotNull);
      // The data source must receive decodable image bytes, not the raw frame.
      expect(img.decodeImage(dataSource.receivedBytes!), isNotNull);
    });
  });
}

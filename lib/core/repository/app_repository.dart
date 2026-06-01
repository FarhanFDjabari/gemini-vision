import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/data/datasource/vision_datasource.dart';
import 'package:image/image.dart' as img;

class AppRepository {
  final VisionDataSource _visionDataSource;

  AppRepository({required VisionDataSource datasource})
    : _visionDataSource = datasource;

  Future<String> getCaption(XFile image) async {
    final processedImage = await processCapturedImage(image);
    return _visionDataSource.getCaption(processedImage);
  }

  Future<Uint8List> processCapturedImage(XFile image) async {
    final imageBytes = await image.readAsBytes();
    return compute(_processImageInIsolate, imageBytes);
  }

  static Uint8List _processImageInIsolate(Uint8List imageBytes) {
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw img.ImageException('Failed to decode image');
    }

    var resizedImage = decodedImage;

    while (resizedImage.lengthInBytes > 10 * 1024 * 1024) {
      resizedImage = img.copyResize(
        resizedImage,
        width: (resizedImage.width * 0.9).toInt(),
      );
    }

    return img.encodePng(resizedImage);
  }
}

final repositoryProvider = Provider((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return AppRepository(datasource: dataSource);
});

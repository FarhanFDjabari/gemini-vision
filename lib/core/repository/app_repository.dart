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

  /// Longest-edge bound for the image sent to the model. The vision encoder
  /// downsamples internally, so anything larger is wasted decode/encode work.
  static const int _maxDimension = 1024;

  static Uint8List _processImageInIsolate(Uint8List imageBytes) {
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw img.ImageException('Failed to decode image');
    }

    final longestSide = decodedImage.width > decodedImage.height
        ? decodedImage.width
        : decodedImage.height;

    final resizedImage = longestSide > _maxDimension
        ? img.copyResize(
            decodedImage,
            width: decodedImage.width >= decodedImage.height
                ? _maxDimension
                : null,
            height: decodedImage.height > decodedImage.width
                ? _maxDimension
                : null,
          )
        : decodedImage;

    return img.encodeJpg(resizedImage, quality: 85);
  }
}

final repositoryProvider = Provider((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return AppRepository(datasource: dataSource);
});

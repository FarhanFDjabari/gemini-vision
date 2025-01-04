import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/data/datasource/app_datasource.dart';
import 'package:image/image.dart' as img;

class AppRepository {
  final AppDataSource _appDataSource;

  AppRepository({required AppDataSource datasource})
      : _appDataSource = datasource;

  Future<String> getCaption(XFile image) async {
    try {
      final processedImage = await processCapturedImage(image);
      final response = await _appDataSource.getCaption(processedImage);
      return response.caption;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> processCapturedImage(XFile image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw img.ImageException("Failed to decode image");
    }

    var resizedImage = decodedImage;

    while (resizedImage.lengthInBytes > 10 * 1024 * 1024) {
      resizedImage = img.copyResize(
        resizedImage,
        width: (resizedImage.width * 0.9).toInt(),
      );
    }

    final pngBytes = img.encodePng(resizedImage);

    return base64Encode(pngBytes);
  }
}

final repositoryProvider = Provider((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return AppRepository(datasource: dataSource);
});

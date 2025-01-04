import 'package:flutter/foundation.dart';

void releaseSafeDebugPrint(String? message, {int? wrapWidth}) {
  if (kDebugMode) {
    debugPrint(message, wrapWidth: wrapWidth);
  }
}

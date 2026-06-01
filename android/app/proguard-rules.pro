# MediaPipe references optional proto classes via reflection that R8 cannot resolve.
-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.proto.**

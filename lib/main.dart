import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/util/provider_observer.dart';
import 'package:gemini_vision/env.dart';
import 'package:gemini_vision/presentation/model_setup_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterGemma.initialize(
    huggingFaceToken: Env.huggingFaceToken.isEmpty
        ? null
        : Env.huggingFaceToken,
  );

  cameras = await availableCameras();

  runApp(ProviderScope(observers: [AppDataObserver()], child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ModelSetupScreen());
  }
}

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_vision/core/data/model/response.dart';
import 'package:gemini_vision/env.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class AppDataSource {
  Future<VisionResponse> getCaption(String base64Image) async {
    final url = Uri.https(
        "generativelanguage.googleapis.com",
        "/v1beta/models/gemini-1.5-flash:generateContent",
        {"key": Env.API_KEY});

    log("HttpRequest:\n$url",
        name: "AppDataSource | getCaption", level: Level.INFO.value);

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Act as a assistant for the visually impaired. Explain the content of the image. Make it simple to understand."
            },
            {
              "inline_data": {"mime_type": "image/png", "data": base64Image}
            }
          ],
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
        "response_schema": {
          "type": "OBJECT",
          "properties": {
            "vision_caption": {"type": "STRING"}
          }
        }
      }
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: requestBody,
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      log(
        """
        HttpResponse:\n
        status code: ${response.statusCode}\n
        body: ${response.body}
        """,
        level: Level.INFO.value,
      );

      final jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes))['candidates'][0]
              ['content']['parts'][0]['text'];
      log("HttpResponse:\n$jsonResponse", name: "AppDataSource | getCaption");
      return VisionResponse.fromJSON(jsonDecode(jsonResponse));
    } else {
      log(
        """
        HttpResponse:\n
        status code: ${response.statusCode}\n
        reason phrase: ${response.reasonPhrase}\n
        body: ${response.body}
        """,
        level: Level.SEVERE.value,
      );
      throw HttpException(response.reasonPhrase ?? "Unknown error", uri: url);
    }
  }
}

final dataSourceProvider = Provider((ref) {
  return AppDataSource();
});

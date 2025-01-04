class VisionResponse {
  final String caption;

  VisionResponse({required this.caption});

  factory VisionResponse.fromJSON(Map<String, dynamic> json) {
    return VisionResponse(
      caption: json['vision_caption'],
    );
  }
}

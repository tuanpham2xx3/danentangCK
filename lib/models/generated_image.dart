class GeneratedImage {
  final String url;
  final String? id;
  final DateTime? createdAt;

  GeneratedImage({
    required this.url,
    this.id,
    this.createdAt,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      url: json['imageURL'] as String, // ✅ dùng đúng trường từ API
      id: json['taskUUID'] as String?, // ✅ lấy id nếu có
      createdAt: null, // ✅ API không có trường này nên để null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

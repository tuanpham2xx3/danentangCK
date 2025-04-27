import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareImage(String imageUrl) async {
    try {
      // Tải ảnh về local
      final tempDir = await getTemporaryDirectory();
      final fileName = 'shared_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(imageUrl, filePath);

      // Share file ảnh
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out this amazing image!',
      );
    } catch (e) {
      print('Error sharing image: $e');
    }
  }
}

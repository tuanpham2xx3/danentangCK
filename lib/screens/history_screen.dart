import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import 'package:dio/dio.dart';
import '../services/share_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _historyImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final images = await _firebaseService.getHistoryImages(user.email!);
      setState(() {
        _historyImages = images;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải lịch sử: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Không thể tải lịch sử');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_historyImages.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text('There are no photos yet', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _historyImages.length,
              itemBuilder: (context, index) {
                final image = _historyImages[index];
                return _buildImageCard(image['imageURL']);
              },
            ),
          ),
      ],
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        _showError('Photo access permission required to save !');
        return;
      }

      final dio = Dio();
      final fileName = 'AI_Image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '/storage/emulated/0/Download/$fileName';

      await dio.download(imageUrl, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved Image: $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi khi tải ảnh: ${e.toString()}');
      }
    }
  }


  Widget _buildImageCard(String imageUrl) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error_outline, color: Colors.red, size: 32),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Hero(
              tag: imageUrl,
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[900]),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error_outline, color: Colors.red, size: 32),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _downloadImage(imageUrl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => ShareService.shareImage(imageUrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
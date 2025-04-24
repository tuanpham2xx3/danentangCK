import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  List<String> _historyImages = [];
  bool _isLoading = true;
  StreamSubscription? _historySubscription;

  @override
  void initState() {
    super.initState();
    _setupHistoryListener();
  }

  void _setupHistoryListener() {
    final user = _authService.currentUser;
    if (user != null) {
      _historySubscription = _firebaseService
          .getImageHistoryStream(user.email!)
          .listen(
            (urls) {
              if (mounted) {
                setState(() {
                  _historyImages = urls;
                  _isLoading = false;
                });
              }
            },
            onError: (error) {
              debugPrint('Error in history stream: $error');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showError('Failed to load history');
              }
            },
          );
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  // Update the GridView.builder to use the new _historyImages list
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
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _historyImages.length,
              itemBuilder: (context, index) {
                final imageUrl = _historyImages[index];
                return _buildImageCard(imageUrl);
              },
            ),
          ),
      ],
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Kiểm tra và yêu cầu quyền truy cập bộ nhớ
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          if (mounted) {
            _showError('Cần cấp quyền truy cập bộ nhớ để lưu ảnh');
          }
          return;
        }
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu ảnh thành công')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to download image: ${e.toString()}');
      }
    }
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            child: Hero(
              tag: imageUrl,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadImage(imageUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
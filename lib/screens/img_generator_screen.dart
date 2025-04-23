import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../models/generated_image.dart';

class ImgGeneratorScreen extends StatefulWidget {
  const ImgGeneratorScreen({super.key});

  @override
  State<ImgGeneratorScreen> createState() => _ImgGeneratorScreenState();
}

class _ImgGeneratorScreenState extends State<ImgGeneratorScreen> {
  final _apiService = ApiService();
  final _firebaseService = FirebaseService();
  final _authService = AuthService();
  final _promptController = TextEditingController();
  
  List<GeneratedImage> _generatedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }



  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) {
      _showError('Please enter a prompt');
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showError('Please login to generate images');
      return;
    }

    // Kiểm tra credit
    final credit = await _firebaseService.getUserCredit(user.email!);
    if (credit < 1) {
      _showError('Not enough credits to generate image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final images = await _apiService.generateImage(
        prompt: _promptController.text,
      );

      if (images.isNotEmpty) {
        // Trừ 1 credit và lưu URL ảnh vào lịch sử
        await Future.wait([
          _firebaseService.updateUserCredit(user.email!, credit.toInt() - 1),
          _firebaseService.addImageToHistory(user.email!, images[0].url),
        ]);

        setState(() {
          _generatedImages = images + _generatedImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to generate image: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Enter your prompt',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Image'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_generatedImages.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Chưa có ảnh nào được tạo'),
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
                    itemCount: _generatedImages.length,
                    itemBuilder: (context, index) {
                      final image = _generatedImages[index];
                      return Column(
                        children: [
                          if (index == 0)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Ảnh mới tạo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(child: _buildImageCard(image.url)),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      // Check and request storage permission
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          if (mounted) {
            _showError('Storage permission is required to save images');
          }
          return;
        }
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
          if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to: $filePath')),
          );
        }
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
                  fit: BoxFit.contain,
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

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
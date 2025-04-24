import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
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
  late StreamSubscription<bool> _premiumSubscription;


  List<GeneratedImage> _generatedImages = [];
  bool _isLoading = false;
  List<String> _onlyPromptImages = [];

  List<Map<String, String>> _models = [];
  String? _selectedModel;
  bool _isPremiumUser = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _premiumSubscription = _firebaseService.getUserPremiumStream(user.email!).listen((status) {
        final wasPremium = _isPremiumUser;
        setState(() {
          _isPremiumUser = status;
        });

        // Nếu từ không premium chuyển thành premium thì load lại model
        if (!wasPremium && status) {
          _loadModels();
        }
      });
    }

    _loadModels(); // vẫn load model ban đầu
  }


  Future<void> _loadModels() async {
    final allModels = await _firebaseService.getAllModels();
    allModels.sort((a, b) {
      final aIsPremium = a['nameModel']!.toLowerCase().contains('premium');
      final bIsPremium = b['nameModel']!.toLowerCase().contains('premium');
      if (!_isPremiumUser) {
        if (aIsPremium && !bIsPremium) return 1;
        if (!aIsPremium && bIsPremium) return -1;
      }
      return 0;
    });

    setState(() {
      _models = allModels;
      if (_models.isNotEmpty) {
        _selectedModel = _models[0]['codeModel'];
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _premiumSubscription.cancel();
    super.dispose();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) {
      _showError('Vui lòng nhập prompt');
      return;
    }

    if (_selectedModel == null) {
      _showError('Vui lòng chọn model');
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _showError('Bạn cần đăng nhập để tạo ảnh');
      return;
    }

    final credit = await _firebaseService.getUserCredit(user.email!);
    if (credit < 1) {
      _showError('Không đủ credit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final images = await _apiService.generateImage(
        prompt: _promptController.text,
        model: _selectedModel!,
      );

      if (images.isNotEmpty) {
        final newUrl = images[0].url;
        await Future.wait([
          _firebaseService.updateUserCredit(user.email!, credit.toInt() - 1),
          _firebaseService.addImageToHistory(user.email!, newUrl),
        ]);

        setState(() {
          _onlyPromptImages.insert(0, newUrl);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi tạo ảnh: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPremiumAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tính năng Premium'),
        content: const Text('Bạn cần nâng cấp tài khoản để sử dụng model Premium.'),
        actions: [
          TextButton(
            child: const Text('Đóng'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      await [
        Permission.storage,
        Permission.photos,
        Permission.mediaLibrary,
      ].request();

      final dio = Dio();
      final fileName = 'AI_Image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '/storage/emulated/0/Download/$fileName';

      await dio.download(imageUrl, savePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu ảnh: $fileName')),
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
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              );
            },
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadImage(imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedModel,
                items: _models.map((model) {
                  final name = model['nameModel']!;
                  final value = model['codeModel']!;
                  final isPremiumModel = name.toLowerCase().contains('premium');
                  final isDisabled = isPremiumModel && !_isPremiumUser;

                  return DropdownMenuItem<String>(
                    value: isDisabled ? null : value,
                    enabled: !isDisabled,
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  final selected = _models.firstWhere((model) => model['codeModel'] == value);
                  final isPremiumModel = selected['nameModel']!.toLowerCase().contains('premium');

                  if (isPremiumModel && !_isPremiumUser) {
                    _showPremiumAlert();
                  } else {
                    setState(() {
                      _selectedModel = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Chọn model',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Nhập prompt',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateImage,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Tạo ảnh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _onlyPromptImages.isEmpty
              ? const Center(child: Text('Chưa có ảnh nào được tạo từ prompt'))
              : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh mới tạo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _onlyPromptImages.length,
                    itemBuilder: (context, index) =>
                        _buildImageCard(_onlyPromptImages[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/ai_model.dart';
import '../models/generated_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  
  @override
  String toString() => message;
}

class ApiService {
  // Sử dụng 10.0.2.2 cho Android Emulator, localhost cho các môi trường khác
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://default-url.com';
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }

  ApiService._internal(){
    print('🌐 API Base URL đang sử dụng: $baseUrl');
  }



  Future<List<AIModel>> getModels() async {
    final response = await get('/api/models');
    final List<dynamic> models = response['models'];
    return models.map((model) => AIModel.fromJson(model)).toList();
  }

  Future<List<GeneratedImage>> getHistory() async {
    final response = await get('/api/history');
    final List<dynamic> history = response['history'];
    return history.map((image) => GeneratedImage.fromJson(image)).toList();
  }

  Future<List<GeneratedImage>> generateImage({
    required String prompt,
  }) async {
    final response = await post('/api/generate-image', {
      'prompt': prompt,
      'model': "runware:100@1",
      'negativePrompt': "",
      'width': 512,
      'height': 512,
      'numberResults': 1,
      'steps': 20,
    });
    final List<dynamic> images = response['data'];
    return images.map((image) => GeneratedImage.fromJson(image)).toList(); 
  }

  Future<void> deleteImage(String imageId) async {
    await delete('/api/images/$imageId');
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Vui lòng thử lại.');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối.');
      } else if (e.toString().contains('timed out')) {
        throw Exception('Request timed out. Vui lòng thử lại.');
      }
      throw Exception('Lỗi khi tải dữ liệu: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
            headers: await _getAuthHeaders(),
          body: json.encode(data),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out. Vui lòng thử lại.');
          },
        );
        
        if (response.statusCode == 503) {
          throw ServerException('Server đang bảo trì, vui lòng thử lại sau.');
        }
        
        return _handleResponse(response);
      } on SocketException catch (e) {
        lastError = Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối internet.');
        retryCount++;
      } on TimeoutException catch (e) {
        lastError = Exception('Request timed out. Vui lòng thử lại.');
        retryCount++;
      } on ServerException catch (e) {
        throw e; // Không retry nếu server đang bảo trì
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        retryCount++;

        if (retryCount >= maxRetries) {
          if (e.toString().contains('Connection refused') || 
              e.toString().contains('Failed host lookup')) {
            throw Exception('Không thể kết nối đến server sau ${maxRetries} lần thử. Vui lòng kiểm tra kết nối và địa chỉ server.');
          } else if (e.toString().contains('timed out')) {
            throw Exception('Request timed out sau ${maxRetries} lần thử. Vui lòng kiểm tra kết nối mạng và thử lại sau.');
          }
          throw Exception('Lỗi khi tạo ảnh sau ${maxRetries} lần thử: ${lastError.toString()}');
        }

        print('Lỗi khi gọi API (lần $retryCount/${maxRetries}): $e');
        print('Thử lại sau ${retryDelay.inSeconds} giây...');
        await Future.delayed(retryDelay);
      }
    }
    throw lastError ?? Exception('Unknown error occurred');
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to perform PUT request: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Vui lòng thử lại.');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối.');
      } else if (e.toString().contains('timed out')) {
        throw Exception('Request timed out. Vui lòng thử lại.');
      }
      throw Exception('Lỗi khi xóa ảnh: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        if (response.body.isEmpty) return null;
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Lỗi khi xử lý dữ liệu JSON: ${e.toString()}');
      }
    }
    
    String errorMessage;
    try {
      final body = json.decode(response.body);
      errorMessage = body['message'] ?? body['error'] ?? 'Lỗi không xác định';
    } catch (e) {
      errorMessage = response.body.isNotEmpty ? response.body : 'Lỗi không xác định';
    }
    
    throw Exception('Lỗi từ server (${response.statusCode}): $errorMessage');
  }
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    if (token == null) {
      throw Exception('Người dùng chưa đăng nhập. Không thể gửi yêu cầu có xác thực.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Connection': 'keep-alive',
    };
  }
}
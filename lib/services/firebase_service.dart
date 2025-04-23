import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  late DatabaseReference _databaseReference;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _databaseReference = FirebaseDatabase.instance.ref();
  }

  DatabaseReference get databaseReference => _databaseReference;

  // ✅ Hàm làm sạch đường dẫn Firebase
  String _sanitizePath(String path) {
    // Giữ nguyên các path đặc biệt như `.info/connected`
    if (path.startsWith(".info")) {
      return path;
    }
    return path.replaceAll(RegExp(r'[.#\$\[\]/]'), '_');
  }

  // ✅ Hàm public gọi từ ngoài class
  String sanitizePath(String path) => _sanitizePath(path);

  Future<void> setData(String path, dynamic data) async {
    await _databaseReference.child(_sanitizePath(path)).set(data);
  }

  Future<dynamic> getData(String path) async {
    final snapshot = await _databaseReference.child(_sanitizePath(path)).get();
    return snapshot.value;
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _databaseReference.child(_sanitizePath(path)).update(data);
  }

  Future<void> deleteData(String path) async {
    await _databaseReference.child(_sanitizePath(path)).remove();
  }

  // Tạo thông tin người dùng mới trong Realtime Database
  Future<void> createUserData(String email) async {
    final userPath = 'users/${_sanitizePath(email)}';
    final Map<String, dynamic> userData = {
      'isPremium': false,
      'credit': 100.0,
      'historyImage': {
        '_init': true
      },
      'email': email,
      'createdAt': DateTime.now().toIso8601String()
    };
    try {
      debugPrint('Bắt đầu tạo dữ liệu người dùng cho email: $email');
      debugPrint('Đường dẫn Firebase: $userPath');
      debugPrint('Dữ liệu sẽ được tạo: $userData');
      
      // Kiểm tra xem dữ liệu đã tồn tại chưa
      final existingData = await getData(userPath);
      if (existingData != null) {
        debugPrint('Dữ liệu người dùng đã tồn tại: $existingData');
        return;
      }
      
      await _databaseReference.child(userPath).set(userData);
      
      // Xác nhận dữ liệu đã được tạo
      final createdData = await getData(userPath);
      debugPrint('Dữ liệu đã được tạo thành công: $createdData');
    } catch (e, stackTrace) {
      debugPrint('Lỗi chi tiết khi tạo dữ liệu người dùng:');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Thêm URL ảnh vào lịch sử của người dùng
  Future<void> addImageToHistory(String email, String imageUrl) async {
    try {
      final sanitizedEmail = _sanitizePath(email);
      final historyPath = 'users/$sanitizedEmail/historyImage';

      final newImageData = {
        'imageURL': imageUrl,
        'timestamp': DateTime.now().toIso8601String()
      };

      // Push thêm ảnh mới vào danh sách historyImage
      await _databaseReference.child(historyPath).push().set(newImageData);
      debugPrint('✅ Đã thêm ảnh vào lịch sử tại $historyPath');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi thêm ảnh vào lịch sử: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
  // Cập nhật trạng thái premium của người dùng
  Future<void> updatePremiumStatus(String email, bool isPremium) async {
    final userPath = 'users/${_sanitizePath(email)}';
    await updateData(userPath, {'isPremium': isPremium});
  }

  // Cập nhật số credit của người dùng
  Future<void> updateUserCredit(String email, int credit) async {
    final creditPath = 'users/${_sanitizePath(email)}/credit';
    await _databaseReference.child(creditPath).set(credit);
  }


  // Theo dõi thay đổi dữ liệu từ một đường dẫn
  Stream<dynamic> getDataStream(String path) {
    return _databaseReference
        .child(_sanitizePath(path))
        .onValue
        .map((event) => event.snapshot.value);
  }

  // Lấy số credit của người dùng
  Future<double> getUserCredit(String email) async {
    try {
      final creditPath = 'users/${_sanitizePath(email)}/credit';
      final snapshot = await _databaseReference.child(creditPath).get();
      final value = snapshot.value;

      print('📥 Giá trị credit từ Firebase: $value (${value.runtimeType})');

      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;

      return 0.0;
    } catch (e, stackTrace) {
      print('🚨 Lỗi khi lấy credit của user $email: $e');
      print('📍 Stack trace: $stackTrace');
      return 0.0;
    }
  }



  // ✅ Stream theo dõi credit của người dùng theo email
  Stream<double> getUserCreditStream(String email) {
    final creditPath = 'users/${_sanitizePath(email)}/credit';
    return _databaseReference.child(creditPath).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    });
  }

  Future<List<Map<String, dynamic>>> getHistoryImages(String email) async {
    final sanitizedEmail = _sanitizePath(email);
    final historyPath = 'users/$sanitizedEmail/historyImage';
    final snapshot = await _databaseReference.child(historyPath).get();

    if (!snapshot.exists) {
      return [];
    }

    final Map<dynamic, dynamic>? data = snapshot.value as Map?;
    if (data == null) return [];

    // Bỏ qua `_init` hoặc các phần tử không hợp lệ
    final images = data.entries
        .where((entry) =>
    entry.key != '_init' &&
        entry.value is Map &&
        (entry.value as Map).containsKey('imageURL'))
        .map((entry) => {
      'imageURL': (entry.value as Map)['imageURL'],
      'timestamp': (entry.value as Map)['timestamp'],
    })
        .toList();

    return images.reversed.toList(); // Trả về danh sách đảo ngược để hiển thị mới nhất trước
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

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
    final userData = {
      'isPremium': false,
      'credit': 100,
      'historyImage': []
    };
    await setData(userPath, userData);
  }

  // Thêm URL ảnh vào lịch sử của người dùng
  Future<void> addImageToHistory(String email, String imageUrl) async {
    final userPath = 'users/${_sanitizePath(email)}/historyImage';
    final currentData = await getData(userPath) ?? [];

    List<dynamic> historyList = List.from(currentData);
    historyList.add({
      'imageURL': imageUrl,
      'timestamp': DateTime.now().toIso8601String()
    });

    await setData(userPath, historyList);
  }

  // Cập nhật trạng thái premium của người dùng
  Future<void> updatePremiumStatus(String email, bool isPremium) async {
    final userPath = 'users/${_sanitizePath(email)}';
    await updateData(userPath, {'isPremium': isPremium});
  }

  // Cập nhật số credit của người dùng
  Future<void> updateUserCredit(String email, int credit) async {
    final userPath = 'users/${_sanitizePath(email)}';
    await updateData(userPath, {'credit': credit});
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
      final userPath = 'users/${_sanitizePath(email)}';
      final userData = await getData(userPath);
      print('Dữ liệu người dùng từ Firebase: $userData');

      if (userData != null && userData is Map) {
        final creditValue = userData['credit'];
        print('Giá trị credit thô: $creditValue');

        if (creditValue != null) {
          // Xử lý các kiểu dữ liệu có thể có
          if (creditValue is int) {
            print('Credit là kiểu int: $creditValue');
            return creditValue.toDouble();
          } else if (creditValue is double) {
            print('Credit là kiểu double: $creditValue');
            return creditValue;
          } else if (creditValue is String) {
            final parsedValue = double.tryParse(creditValue);
            print('Credit là kiểu String: $creditValue, sau khi parse: $parsedValue');
            return parsedValue ?? 0.0;
          }
          print('Credit có kiểu dữ liệu không xác định: ${creditValue.runtimeType}');
          return 0.0;
        }
      }
      print('Không tìm thấy credit cho user $email');
      return 0.0;
    } catch (e) {
      print('Lỗi khi lấy credit của user $email: $e');
      return 0.0;
    }
  }

  // ✅ Stream theo dõi credit của người dùng theo email
  Stream<double> getUserCreditStream(String email) {
    final path = 'users/${_sanitizePath(email)}';
    return _databaseReference.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data is Map && data['credit'] != null) {
        final creditValue = data['credit'];
        if (creditValue is int) return creditValue.toDouble();
        if (creditValue is double) return creditValue;
        if (creditValue is String) return double.tryParse(creditValue) ?? 0.0;
      }
      return 0.0;
    });
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late DatabaseReference _databaseReference;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _databaseReference = FirebaseDatabase.instance.ref();
  }

  DatabaseReference get databaseReference => _databaseReference;

  String _sanitizePath(String path) {
    if (path.startsWith(".info")) return path;
    return path.replaceAll(RegExp(r'[.#\\$\[\]/]'), '_');
  }

  String sanitizePath(String path) => _sanitizePath(path);

  Future<void> setData(String path, dynamic data) async {
    await _databaseReference.child(path).set(data);
  }

  Future<dynamic> getData(String path) async {
    final snapshot = await _databaseReference.child(path).get();
    return snapshot.value;
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _databaseReference.child(path).update(data);
  }

  Future<void> deleteData(String path) async {
    await _databaseReference.child(path).remove();
  }

  Future<void> createUserData(String email) async {
    final userPath = 'users/${_sanitizePath(email)}';
    final userData = {
      'isPremium': false,
      'credit': 5.0,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
      'historyImage': [],
    };
    final existingData = await getData(userPath);
    if (existingData != null) return;
    await setData(userPath, userData);
  }

  Future<void> updatePremiumStatus(String email, bool isPremium) async {
    final userPath = 'users/${_sanitizePath(email)}';
    await updateData(userPath, {'isPremium': isPremium});
  }

  Future<void> updateUserCredit(String email, int credit) async {
    final userPath = 'users/${_sanitizePath(email)}';
    await updateData(userPath, {'credit': credit});
  }

  Future<double> getUserCredit(String email) async {
    try {
      final path = 'users/${_sanitizePath(email)}/credit';
      final snapshot = await _databaseReference.child(path).get();
      final value = snapshot.value;
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      print('Lỗi khi lấy credit của user $email: $e');
      return 0.0;
    }
  }

  Stream<double> getUserCreditStream(String email) {
    final path = 'users/${_sanitizePath(email)}/credit';
    return _databaseReference.child(path).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    });
  }

  Future<bool> getUserPremiumStatus(String email) async {
    try {
      final path = 'users/${_sanitizePath(email)}/isPremium';
      final snapshot = await _databaseReference.child(path).get();
      final value = snapshot.value;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    } catch (e) {
      debugPrint('Lỗi khi lấy trạng thái Premium: $e');
      return false;
    }
  }

  Stream<bool> getUserPremiumStream(String email) {
    final path = 'users/${_sanitizePath(email)}/isPremium';
    return _databaseReference.child(path).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    });
  }

  Future<void> addImageToHistory(String email, String imageUrl) async {
    try {
      final userPath = 'users/${_sanitizePath(email)}/historyImage';
      final snapshot = await _databaseReference.child(userPath).get();

      List<dynamic> historyList = [];
      if (snapshot.exists && snapshot.value is List) {
        historyList = List.from(snapshot.value as List);
      }

      historyList.add({
        'imageURL': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _databaseReference.child(userPath).set(historyList);
      debugPrint('✅ Đã thêm ảnh vào lịch sử tại $userPath');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi thêm ảnh vào lịch sử: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getHistoryImages(String email) async {
    final path = 'users/${_sanitizePath(email)}/historyImage';
    final snapshot = await _databaseReference.child(path).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final data = snapshot.value;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((img) => {
        'imageURL': img['imageURL']?.toString() ?? '',
        'timestamp': img['timestamp']?.toString() ?? '',
      })
          .toList()
          .reversed
          .toList();
    }
    return [];
  }

  Stream<List<Map<String, String>>> getImageHistoryStream(String email) {
    final path = 'users/${_sanitizePath(email)}/historyImage';
    return _databaseReference.child(path).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! List) return [];
      try {
        final images = data
            .whereType<Map>()
            .map((entry) => {
          'imageURL': entry['imageURL']?.toString() ?? '',
          'timestamp': entry['timestamp']?.toString() ?? '',
        })
            .toList();
        return images.reversed.toList();
      } catch (e) {
        debugPrint('Error parsing history data: $e');
        return [];
      }
    });
  }

  Future<List<Map<String, String>>> getAllModels() async {
    final snapshot = await _databaseReference.child('models').get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final data = snapshot.value;
    if (data is Map) {
      return data.entries.map((entry) {
        final value = entry.value;
        return {
          'nameModel': value['nameModel']?.toString() ?? '',
          'codeModel': value['codeModel']?.toString() ?? '',
        };
      }).toList();
    }
    return [];
  }

}

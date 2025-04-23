import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Kiểm tra và khởi tạo Firebase Auth
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Đợi Firebase Auth khởi tạo hoàn tất và kiểm tra trạng thái đăng nhập
      await Future.delayed(const Duration(seconds: 1));
      final user = _auth.currentUser;
      if (user != null) {
        // Kiểm tra token hợp lệ
        try {
          await user.getIdToken(true);
          debugPrint('Token hợp lệ cho user ${user.uid}');
        } catch (e) {
          debugPrint('Token không hợp lệ, đăng xuất user');
          await signOut();
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo Firebase Auth: $e');
      rethrow;
    }
  }

  // Lấy thông tin người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký bằng email và mật khẩu
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Thêm xử lý lỗi chi tiết hơn
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Không thể tạo người dùng mới',
        );
      }

      try {
        // Tạo dữ liệu người dùng trong Realtime Database
        await FirebaseService().createUserData(email);
        debugPrint('Đã tạo dữ liệu người dùng thành công cho: $email');
      } catch (dbError, stackTrace) {
        // Xử lý lỗi khi tạo dữ liệu người dùng
        debugPrint('Lỗi chi tiết khi tạo dữ liệu người dùng:');
        debugPrint('Error: $dbError');
        debugPrint('Kiểu lỗi: ${dbError.runtimeType}');
        debugPrint('Stack trace: $stackTrace');
        
        // Vẫn trả về credential nhưng ghi log lỗi
        debugPrint('Tài khoản đã được tạo nhưng có lỗi khi khởi tạo dữ liệu người dùng');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Log lỗi để dễ dàng debug
      debugPrint('Lỗi Firebase Auth khi đăng ký: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Lỗi không xác định khi đăng ký:');
      debugPrint('Error: $e');
      debugPrint('Kiểu lỗi: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Đăng nhập bằng email và mật khẩu
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Đăng nhập thành công - UID: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Lỗi Firebase Auth khi đăng nhập: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Lỗi không xác định khi đăng nhập: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Quên mật khẩu
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
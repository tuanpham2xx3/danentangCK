import 'package:firebase_auth/firebase_auth.dart';
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
          print('Token hợp lệ cho user ${user.uid}');
        } catch (e) {
          print('Token không hợp lệ, đăng xuất user');
          await signOut();
        }
      }
      _isInitialized = true;
    } catch (e) {
      print('Lỗi khởi tạo Firebase Auth: $e');
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Tạo dữ liệu người dùng trong Realtime Database
      await FirebaseService().createUserData(email);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      // Log lỗi để dễ dàng debug
      print('Lỗi Firebase Auth khi đăng ký: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Lỗi không xác định khi đăng ký: $e');
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
      print('Đăng nhập thành công - UID: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Lỗi Firebase Auth khi đăng nhập: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Lỗi không xác định khi đăng nhập: $e');
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
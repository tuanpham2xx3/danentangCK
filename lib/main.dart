import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MobileAds.instance.initialize(); // Khởi tạo SDK quảng cáo

  try {
    // Khởi tạo Firebase với các tùy chọn cụ thể cho từng nền tảng
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyBBxFav8mSqLhtXFOhMTqeW-7qF49uxzZ8',
        appId: '1:853795611602:android:e5f16a61ec705f34721e0b',
        messagingSenderId: '853795611602',
        projectId: 'danentang-4cfc9',
        databaseURL: 'https://danentang-4cfc9-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'danentang-4cfc9.firebasestorage.app',
      ),
    );
    
    // Khởi tạo các services
    final firebaseService = FirebaseService();
    final authService = AuthService();
    
    await Future.wait([
      firebaseService.initialize(),
      authService.initialize(),
    ]);
    
    debugPrint('Khởi tạo Firebase và Auth thành công');
  } catch (e) {
    debugPrint('Lỗi khởi tạo ứng dụng: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Nếu người dùng đã đăng nhập, chuyển đến màn hình chính
        if (snapshot.hasData) {
          return const MainScreen();
        }
        // Nếu chưa đăng nhập, chuyển đến màn hình đăng nhập
        return const LoginScreen();
      },
    );
  }
}

import 'package:danentang/screens/history_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'explore_screen.dart';
import 'my_space_screen.dart';
import 'img_generator_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  late Stream<double> _creditsStream;

  @override
  void initState() {
    super.initState();
    _initCreditsStream();
  }

  void _initCreditsStream() {
    final user = _authService.currentUser;
    if (user != null) {
      _creditsStream = _firebaseService
          .getUserCreditStream(user.email!)
          .asBroadcastStream();
    } else {
      _creditsStream = Stream.value(0.0);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  final List<Widget> _screens = [
    const ImgGeneratorScreen(),
    const ExploreScreen(),
    const SizedBox(), // Placeholder for create button
    const HistoryScreen(),
    const MySpaceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: StreamBuilder<double>(
        stream: _creditsStream,
        initialData: 0.0,
        builder: (context, snapshot) {
          return KlingDrawer(
            credits: snapshot.data ?? 0.0,
            onUpgradePlan: () {
              // TODO: Implement upgrade plan
            },
            onSignOut: _handleSignOut,
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StreamBuilder<double>(
              stream: _creditsStream,
              initialData: 0.0,
              builder: (context, snapshot) {
                return Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      (snapshot.data ?? 0.0).toStringAsFixed(2),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: KlingBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onCreateTap: _showCreateOptions,
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCreateOption(context, Icons.image, 'Image'),
                  _buildCreateOption(context, Icons.videocam, 'Video'),
                  _buildCreateOption(context, Icons.text_fields, 'Text'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageGenerator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('AI Image Generator'),
            elevation: 0,
          ),
          body: const ImgGeneratorScreen(),
        ),
      ),
    );
  }

  Widget _buildCreateOption(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (label == 'Image') {
          setState(() {
            _currentIndex = 0;
          });
          _showImageGenerator();
        }
        // Handle other options
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

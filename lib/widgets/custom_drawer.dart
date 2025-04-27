import 'package:flutter/material.dart';
import 'package:danentang/services/auth_service.dart';
import 'package:danentang/services/firebase_service.dart';
import 'package:danentang/helpers/rewarded_ad_helper.dart'; // nhớ tạo file này
import 'package:google_mobile_ads/google_mobile_ads.dart';

class KlingDrawer extends StatefulWidget {
  final double credits;
  final VoidCallback onUpgradePlan;
  final VoidCallback onSignOut;

  const KlingDrawer({
    super.key,
    required this.credits,
    required this.onUpgradePlan,
    required this.onSignOut,
  });

  @override
  State<KlingDrawer> createState() => _KlingDrawerState();
}

class _KlingDrawerState extends State<KlingDrawer> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final email = _authService.currentUser?.email;
    if (email != null) {
      final premium = await _firebaseService.getUserPremiumStatus(email);
      setState(() {
        _isPremium = premium;
      });
    }
  }

  void _showCongratulationDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? 'Not signed in';

    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: _isPremium ? Colors.amber : Colors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPremium ? 'Premium' : 'Trial',
                      style: TextStyle(
                        color: _isPremium ? Colors.amber : Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nếu chưa Premium
          if (!_isPremium)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.yellow),
                title: const Text(
                  'GET PREMIUM',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Use Premium Model',
                  style: TextStyle(color: Colors.black87),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black),
                onTap: () {
                  final email = _authService.currentUser?.email;
                  if (email == null) return;

                  RewardedAdHelper().loadAd(() async {
                    await _firebaseService.updatePremiumStatus(email, true);
                    setState(() => _isPremium = true);

                    _showCongratulationDialog(
                        "🎉 Congratulations!",
                        "You have successfully upgraded to Premium!"
                    );
                  });
                },
              ),
            ),

          // Nhận thêm credit
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.yellow),
              title: const Text(
                'GET MORE CREDIT',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Get more 10 credits',
                style: TextStyle(color: Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black),
              onTap: () {
                final email = _authService.currentUser?.email;
                if (email == null) return;

                RewardedAdHelper().loadAd(() async {
                  double current = await _firebaseService.getUserCredit(email);
                  await _firebaseService.updateUserCredit(email, (current + 10).toInt());

                  _showCongratulationDialog(
                      "🎁 Great!",
                      "You have received 10 more credits!"
                  );
                });
              },
            ),
          ),

          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.white),
            title: const Text('Help Center', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: Colors.white),
            title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.white),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.white),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('About Us', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: widget.onSignOut,
          ),
        ],
      ),
    );
  }
}

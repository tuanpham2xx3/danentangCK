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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

          // Chỉ hiển thị nút GET PREMIUM nếu chưa phải Premium
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
                    _showSnack("🎉 You have successfully upgraded to Premium!");
                  });
                },
              ),
            ),

          // Nút nhận thêm credit
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
                  _showSnack("🎁 Get 10 more credits successfully!");
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
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Information Shared with Third Party',
                style: TextStyle(color: Colors.white)),
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

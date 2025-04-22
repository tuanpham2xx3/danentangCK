import 'package:danentang/services/auth_service.dart';
import 'package:flutter/material.dart';

class KlingDrawer extends StatelessWidget {
  final double credits;
  final VoidCallback onUpgradePlan;
  final VoidCallback onSignOut;
  final AuthService _authService = AuthService();

  KlingDrawer({
    super.key,
    required this.credits,
    required this.onUpgradePlan,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
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
                  _authService.currentUser?.email ?? 'Not signed in',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Upgrade Plan
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.star_border, color: Colors.black),
              title: const Text(
                'Upgrade your plan',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'More Credits & Premium Features',
                style: TextStyle(color: Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black),
              onTap: onUpgradePlan,
            ),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.white),
            title: const Text('Help Center', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          // Contact Us
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
          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description, color: Colors.white),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          // Information Shared with Third Party
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Information Shared with Third Party',
                style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          // About Us
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('About Us', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.grey),
          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}
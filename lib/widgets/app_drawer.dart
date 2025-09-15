import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eczane_vs/providers/location_provider.dart';
import 'package:eczane_vs/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/admin_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _auth.userChanges().listen((updatedUser) {
      setState(() {
        user = updatedUser;
      });
    });
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Future<bool> _isAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      print('Admin check error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final location = locationProvider.location;

    final displayName = user?.displayName?.trim();
    final emailPrefix = user?.email?.split('@').first ?? "Kullanıcı";
    final nameToShow = displayName != null && displayName.isNotEmpty
        ? displayName
        : emailPrefix;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: user?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  _getInitials(nameToShow),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(nameToShow),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  nameToShow,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (location != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${location['city']} / ${location['district']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_outlined,
                  text: 'Ana Sayfa',
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.local_pharmacy_outlined,
                  text: 'Eczane Ara',
                  onTap: () => Navigator.pushNamed(context, '/pharmacy-list'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  text: 'Hesap Bilgilerim',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.location_on_outlined,
                  text: 'Konum Bilgilerim',
                  onTap: () => Navigator.pushNamed(context, '/location'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.campaign_outlined,
                  text: 'Duyurular',
                  onTap: () => Navigator.pushNamed(context, '/announcements'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_outlined,
                  text: 'Bildirimler',
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                const Divider(height: 32),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  text: 'Hakkında',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: "Nöbetçi Eczane",
                    applicationVersion: "1.0.0",
                    children: [
                      const Text(
                        "Bu uygulama size nöbetçi eczaneleri gösterir.",
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  text: 'Tema',
                  onTap: () => themeProvider.toggleTheme(),
                  trailing: Switch(
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return _buildDrawerItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        text: 'Yönetici Paneli',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  text: 'Çıkış Yap',
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () async {
                    await _auth.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

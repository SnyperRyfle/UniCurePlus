import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../services/auth_api.dart';
import '../services/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/common_widgets.dart';
import '../widgets/primary_button.dart';

/// V15 - Profil syarikat (Company profile)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthSession.instance.logout();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const c = DummyData.company;
    return Scaffold(
      appBar: const BrandAppBar(),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('Profil syarikat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandGold,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.brandPurple,
                    child: Icon(
                      Icons.business,
                      size: 36,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                const StatusPill(label: 'Pembekal berdaftar'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  DetailRow(label: 'No. pendaftaran', value: c.registrationNo),
                  const Divider(),
                  DetailRow(label: 'Kategori', value: c.category),
                  const Divider(),
                  DetailRow(label: 'E-mel', value: c.email),
                  const Divider(),
                  DetailRow(label: 'Telefon', value: c.phone),
                  const Divider(),
                  DetailRow(label: 'Alamat', value: c.address),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _isLoggingOut ? 'Sedang log keluar...' : 'Log keluar',
            icon: Icons.logout,
            onPressed: _isLoggingOut ? null : _logout,
          ),
        ],
      ),
    );
  }
}

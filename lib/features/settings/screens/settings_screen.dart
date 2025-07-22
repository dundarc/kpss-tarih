import 'dart:io'; // Platform kontrolü için eklendi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/core/theme/theme_provider.dart';
import 'package:kpss_tarih_app/features/settings/screens/privacy_policy_screen.dart';
import 'package:kpss_tarih_app/features/settings/screens/terms_of_use_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Uygulama versiyonunu asenkron olarak almak için bir provider.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // URL açma yardımcı fonksiyonu
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Hata durumunda bir şey yapabilirsiniz, örneğin bir SnackBar göstermek.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentTheme = ref.watch(themeProvider);
    final userData = ref.watch(userDataProvider);

    String subscriptionStatus;
    if (userData.isLifetimePremium) {
      subscriptionStatus = 'Ömür Boyu Premium';
    } else if (userData.isPremium) {
      subscriptionStatus = 'Premium Üye';
    } else {
      subscriptionStatus = 'Standart Üye';
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _SettingsHeader(title: 'Görünüm'),
          _SettingsCard(
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('Açık'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('Sistem'),
                    icon: Icon(Icons.brightness_auto)),
                ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('Koyu'),
                    icon: Icon(Icons.dark_mode)),
              ],
              selected: {currentTheme},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                themeNotifier.setTheme(newSelection.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: 'Abonelik'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Üyelik Durumu'),
                  trailing: Text(
                    subscriptionStatus,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Satın Almaları Geri Yükle'),
                  onTap: () {
                    // Not: Bu fonksiyonun çalışması için PurchaseService'inizin
                    // ve ilgili provider'ın (purchaseServiceProvider) ayarlanmış olması gerekir.
                    // ref.read(purchaseServiceProvider).restorePurchases();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Satın alma geçmişi kontrol ediliyor...')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Abonelikleri Yönet'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Kullanıcıyı platforma özel abonelik yönetimi sayfasına yönlendirir.
                    String url = 'https://play.google.com/store/account/subscriptions'; // Android için varsayılan
                    if (Platform.isIOS) {
                      url = 'https://apps.apple.com/account/subscriptions';
                    }
                    _launchURL(url);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SettingsHeader(title: 'Hakkında'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Gizlilik Politikası'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Kullanım Koşulları'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsOfUseScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Uygulama versiyonunu gösteren alan
          Consumer(
            builder: (context, ref, child) {
              final packageInfo = ref.watch(packageInfoProvider);
              return packageInfo.when(
                data: (info) => Text(
                  'Versiyon: ${info.version} (${info.buildNumber})',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Versiyon bilgisi alınamadı', textAlign: TextAlign.center),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Ayarlar ekranında bölümleri ayırmak için kullanılan başlık widget'ı
class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// Ayarlar ekranındaki her bir kart için standart bir görünüm sağlayan widget
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

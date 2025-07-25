import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/features/home/screens/home_screen.dart';
import 'package:kpss_tarih_app/features/settings/screens/settings_screen.dart';
import 'package:kpss_tarih_app/features/store/screens/store_screen.dart';
import 'package:kpss_tarih_app/features/topics/screens/category_list_screen.dart';
import 'dart:async'; // Timer için eklendi
import 'package:connectivity_plus/connectivity_plus.dart'; // İnternet kontrolü için eklendi

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  Timer? _dailyTimer;
  Timer? _timeSpentTimer;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryListScreen(),
    const StoreScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowWelcomePopup();
      _startDailyTasksCheck();
      _startTimeSpentTracking();
      _checkPastPurchases(); // *** YENİ: Uygulama açılışında satın almaları kontrol et ***
    });
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    _timeSpentTimer?.cancel();
    super.dispose();
  }

  // *** YENİ FONKSİYON: Geçmiş satın almaları internet varsa kontrol eder ***
  void _checkPastPurchases() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    // Cihazın internete bağlı olup olmadığını kontrol et (none değilse bağlıdır)
    if (connectivityResult.first != ConnectivityResult.none) {
      // İnternet varsa, satın almaları geri yükleme işlemini tetikle.
      // Bu işlem, PurchaseService içindeki restorePurchases metodunu çağırır.
      ref.read(purchaseServiceProvider).restorePurchases();
      print("İnternet bağlantısı var, geçmiş satın alımlar kontrol ediliyor.");
    } else {
      print("İnternet bağlantısı yok, satın alma kontrolü atlandı.");
    }
  }

  void _checkAndShowWelcomePopup() {
    final userData = ref.read(userDataProvider);
    if (!userData.hasSeenWelcomePopup) {
      _showWelcomePopup(context);
      ref.read(userDataProvider.notifier).markWelcomePopupSeen();
    }
  }

  void _startDailyTasksCheck() {
    _checkDailyPremiumReward();
    _dailyTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkDailyPremiumReward();
    });
  }

  void _checkDailyPremiumReward() {
    final success = ref.read(userDataProvider.notifier).claimDailyPremiumReward();
    if (success) {
      // SnackBar'ı göstermek için context'in hala geçerli olduğundan emin ol
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium günlük elmas ödülünüzü kazandınız! (+1 Elmas)')),
        );
      }
    }
  }

  void _startTimeSpentTracking() {
    _timeSpentTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      ref.read(userDataProvider.notifier).updateTimeSpent(1);
      final userData = ref.read(userDataProvider);
      print('Uygulamada geçirilen süre: ${userData.timeSpentMinutesToday} dakika');
    });
  }


  void _onItemTapped(int index) {
    ref.read(mainNavigationSelectedIndexProvider.notifier).state = index;
  }

  void _showDiamondInfoPopup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond, size: 60, color: theme.colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  'Elmasların Ne İşe Yarar?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Elmaslar, testlerde "Yarı Yarıya Joker" kullanmak ve konu anlatımlarındaki "Püf Noktalarını" açmak için kullanılır.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Popup'ı kapat
                      ref.read(mainNavigationSelectedIndexProvider.notifier).state = 2; // Mağaza sekmesi indeksi
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    label: Text(
                      'Daha Fazla Elmas Al',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Popup'ı kapat
                  },
                  child: Text(
                    'Kapat',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWelcomePopup(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'KPSS Tarih Uygulamasına Hoş Geldiniz!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu uygulama ile KPSS Tarih konularını detaylıca öğrenebilir, her konunun sonunda test çözebilir, rastgele sorularla bilginizi pekiştirebilirsiniz. Elmaslarınızı joker ve püf noktalarını açmak için kullanmayı unutmayın!',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Popup'ı kapat
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Hadi Başlayalım!',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
    final selectedIndex = ref.watch(mainNavigationSelectedIndexProvider);
    final diamondCount = ref.watch(userDataProvider.select((data) => data.diamondCount));
    final theme = Theme.of(context);

    String appBarTitle;
    switch (selectedIndex) {
      case 0:
        appBarTitle = 'Ana Sayfa';
        break;
      case 1:
        appBarTitle = 'Konular';
        break;
      case 2:
        appBarTitle = 'Mağaza';
        break;
      case 3:
        appBarTitle = 'Ayarlar';
        break;
      default:
        appBarTitle = 'KPSS Tarih';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          GestureDetector(
            onTap: () {
              _showDiamondInfoPopup(context, ref);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.diamond_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '$diamondCount',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Konular'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Mağaza'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}

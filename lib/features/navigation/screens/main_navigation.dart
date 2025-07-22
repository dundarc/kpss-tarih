import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpss_tarih_app/core/providers/providers.dart';
import 'package:kpss_tarih_app/features/home/screens/home_screen.dart';
import 'package:kpss_tarih_app/features/settings/screens/settings_screen.dart';
import 'package:kpss_tarih_app/features/store/screens/store_screen.dart';
import 'package:kpss_tarih_app/features/topics/screens/category_list_screen.dart'; // GÜNCELLENDİ

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryListScreen(), // GÜNCELLENDİ
    const StoreScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final diamondCount = ref.watch(userDataProvider.select((data) => data.diamondCount));
    final theme = Theme.of(context);

    String appBarTitle;
    switch (_selectedIndex) {
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
          Padding(
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
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
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

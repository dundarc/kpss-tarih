import 'package:flutter/material.dart';

// Her bir kategori kartının yapısını tanımlayan model sınıfı
class Category {
  final String id;
  final String title;
  final String description;
  final String jsonPath; // Her kategorinin kendi JSON dosyasının yolu
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.title,
    required this.description,
    required this.jsonPath,
    required this.icon,
    required this.color,
  });
}

// Uygulamada kullanılacak 8 ana kategorinin listesi
const List<Category> historyCategories = [
  Category(
    id: 'cat1',
    title: 'İslamiyet Öncesi Türk Tarihi',
    description: 'İlk Türk devletleri, kültür ve yaşam.',
    jsonPath: '/content/islamiyet_oncesi.json',
    icon: Icons.shield_outlined,
    color: Colors.blue,
  ),
  Category(
    id: 'cat2',
    title: 'İlk Müslüman Türk Devletleri',
    description: 'Karahanlı, Gazneli, Selçuklu dönemi.',
    jsonPath: '/content/ilk_musluman.json',
    icon: Icons.mosque_outlined,
    color: Colors.teal,
  ),
  Category(
    id: 'cat3',
    title: 'Anadolu Selçuklu Devleti',
    description: 'Anadolu\'nun Türkleşmesi ve beylikler.',
    jsonPath: '/content/anadolu_selcuklu.json',
    icon: Icons.fort,
    color: Colors.brown,
  ),
  Category(
    id: 'cat4',
    title: 'Osmanlı İmparatorluğu',
    description: 'Kuruluş, Yükselme ve Duraklama.',
    jsonPath: '/content/osmanli_devleti.json',
    icon: Icons.castle,
    color: Colors.red,
  ),
  Category(
    id: 'cat5',
    title: 'Osmanlı Kültür ve Medeniyeti',
    description: 'Devlet yapısı, toplum ve sanat.',
    jsonPath: '/content/osmanli_kultur.json',
    icon: Icons.palette_outlined,
    color: Colors.purple,
  ),
  Category(
    id: 'cat6',
    title: 'Milli Mücadele Dönemi',
    description: 'Kurtuluş Savaşı ve hazırlık süreci.',
    jsonPath: '/content/milli_mucadele.json',
    icon: Icons.flag_outlined,
    color: Colors.orange,
  ),
  Category(
    id: 'cat7',
    title: 'Cumhuriyet Dönemi',
    description: 'Atatürk ilkeleri, inkılaplar ve dış politika.',
    jsonPath: '/content/cumhuriyet_donemi.json',
    icon: Icons.account_balance_outlined,
    color: Colors.green,
  ),
  Category(
    id: 'cat8',
    title: 'Yakın Dünya Tarihi',
    description: 'Dünya Savaşları ve Soğuk Savaş.',
    jsonPath: '/content/yakin_dunya_tarihi.json',
    icon: Icons.public,
    color: Colors.indigo,
  ),
];

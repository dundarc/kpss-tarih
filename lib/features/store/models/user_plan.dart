// lib/features/store/models/user_plan.dart

/// Kullanıcının abonelik durumunu temsil eden enum.
enum UserPlan {
  /// Standart, reklamlı kullanıcı.
  free,

  /// Aylık veya yıllık aboneliği aktif olan, reklamsız kullanıcı.
  premium,

  /// Ömür boyu lisans satın almış, reklamsız ve potansiyel olarak
  /// ekstra özelliklere sahip kullanıcı.
  fullPremium,
}

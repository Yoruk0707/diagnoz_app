// lib/core/utils/date_utils.dart
//
// NEDEN: ISO 8601 hafta numarası hesaplama — shared utility.
// Hem game datasource (write) hem leaderboard repository (read)
// aynı weekNumber üretmeli. DRY prensibi — iki yerde ayrı
// hesaplama tutarsızlık yaratır (bkz. weekNumber 7 vs 8 bug).

/// ISO 8601 hafta numarası hesapla.
///
/// NEDEN: Leaderboard document ID'si ve query'si weekNumber kullanır.
/// Write ve read tarafı aynı fonksiyonu kullanmalı — tutarsızlık
/// leaderboard'un boş görünmesine neden olur.
///
/// ISO 8601 kuralı: haftanın Perşembe gününe bak.
/// Yılın ilk Perşembe'si 1. haftanın içindedir.
/// Pazartesi = hafta başlangıcı (Türkiye standardı).
int getIsoWeekNumber(DateTime date) {
  // NEDEN: ISO 8601 — Perşembe'nin yılı ve günü baz alınır.
  // Bu algoritma yıl geçişlerini de doğru hesaplar.
  final thursday =
      date.add(Duration(days: DateTime.thursday - date.weekday));
  final jan1 = DateTime(thursday.year, 1, 1);
  final dayOfYear = thursday.difference(jan1).inDays;
  return (dayOfYear / 7).floor() + 1;
}

/// Enforces the Protestant 66-book canon on Bible DB query results.
///
/// The MySword/TheWord open DB standard assigns book_number values that are
/// exact multiples of 10 (10–730) to all 66 canonical books. Deuterocanonical
/// books occupy the gap slots with non-multiples-of-10 (170, 180, 192, etc.)
/// or values > 730.
///
/// The canonical set mirrors bible_books.json in DevocionalesAPI (pipeline SOT).
/// This is a constant — the MySword standard does not change.
class BibleCanonFilter {
  BibleCanonFilter._();

  static const Set<int> _canonicalNumbers = {
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    110,
    120,
    130,
    140,
    150,
    160,
    190,
    220,
    230,
    240,
    250,
    260,
    290,
    300,
    310,
    330,
    340,
    350,
    360,
    370,
    380,
    390,
    400,
    410,
    420,
    430,
    440,
    450,
    460,
    470,
    480,
    490,
    500,
    510,
    520,
    530,
    540,
    550,
    560,
    570,
    580,
    590,
    600,
    610,
    620,
    630,
    640,
    650,
    660,
    670,
    680,
    690,
    700,
    710,
    720,
    730,
  };

  /// Returns true if [bookNumber] belongs to the Protestant 66-book canon.
  static bool isCanonical(int bookNumber) =>
      _canonicalNumbers.contains(bookNumber);

  /// Filters [books] to only Protestant canonical books.
  /// Books must have a 'book_number' int field (MySword standard).
  /// No-op for clean 66-book DBs — all rows pass through unchanged.
  static List<Map<String, dynamic>> filterCanonical(
    List<Map<String, dynamic>> books,
  ) =>
      books.where((b) => isCanonical(b['book_number'] as int)).toList();
}

/// A food item shown on cards, search results, and the detail screen.
///
/// Mirrors the backend `food_catalog` table: serving is expressed as
/// [quantity] + [unit] (e.g. 100 + "g", 1 + "medium", 0.5 + "cup"), not
/// grams-only. The detail screen scales kcal/macros relative to [quantity].
///
/// `imageUrl` is non-null. If the backend doesn't return one, callers should
/// pass [Food.placeholderImage] so the UI never has to handle a null image.
/// `imageUrl` may be either a network URL (starts with http/https) or a local
/// asset path — the detail screen picks the right Image widget at render time.
class Food {
  /// Local asset used when the backend has no image for a food yet.
  static const String placeholderImage = 'assets/images/food_image.png';

  final String name;

  /// Network URL or asset path. Never null — defaults to [placeholderImage].
  final String imageUrl;

  /// Calories per [quantity] [unit].
  final double kcal;

  /// Macronutrients in grams per [quantity] [unit].
  final double carbsG;
  final double proteinG;
  final double fatG;

  /// Default serving amount, in [unit]. e.g. 100 with unit "g", or 1 with
  /// unit "medium". The detail screen lets the user scale this up/down.
  final double quantity;

  /// Free-text unit label (e.g. "g", "ml", "medium", "cup", "slice").
  /// Backend stores this as plain text in `food_catalog.unit`.
  final String unit;

  Food({
    required this.name,
    this.imageUrl = placeholderImage,
    this.kcal = 0,
    this.carbsG = 0,
    this.proteinG = 0,
    this.fatG = 0,
    this.quantity = 100,
    this.unit = 'g',
  });

  /// Builds a [Food] from a `food_catalog`-shaped JSON object — used by both
  /// `/recipes/search` (which wraps it in `data`) and any future endpoint
  /// that returns the same row shape.
  ///
  /// The backend serialises numeric columns as strings ("600", "15"), so we
  /// run every numeric field through [_parseDouble] rather than casting.
  /// `image_url` may be null in the response — fall back to [placeholderImage]
  /// so the UI never has to handle nulls.
  /// Builds the per-item JSON map that POST /meals expects.
  ///
  /// The detail screen scales kcal/macros based on the user-chosen serving,
  /// so we let callers override the numeric fields. When omitted, the food's
  /// default values are used. `foodCatalogId` is optional because some foods
  /// (e.g. AI-generated suggestions not yet in the catalog) won't have one.
  Map<String, dynamic> toMealItemJson({
    int? foodCatalogId,
    double? quantity,
    double? calories,
    double? carbsG,
    double? proteinG,
    double? fatG,
  }) {
    return {
      'foodCatalogId': foodCatalogId,
      'foodName': name,
      'imageUrl': imageUrl,
      'quantity': quantity ?? this.quantity,
      'unit': unit,
      'calories': calories ?? kcal,
      'protein_g': proteinG ?? this.proteinG,
      'carbs_g': carbsG ?? this.carbsG,
      'fat_g': fatG ?? this.fatG,
    };
  }

  factory Food.fromCatalogJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'];
    return Food(
      name: (json['food_name'] ?? '').toString(),
      imageUrl: (rawImage is String && rawImage.isNotEmpty)
          ? rawImage
          : placeholderImage,
      kcal: _parseDouble(json['calories']),
      carbsG: _parseDouble(json['carbs_g']),
      proteinG: _parseDouble(json['protein_g']),
      fatG: _parseDouble(json['fat_g']),
      // Default to 1 (not 100) so AI-generated entries like "1 จาน" stay
      // sensible even if quantity is missing.
      quantity: _parseDouble(json['quantity'], fallback: 1),
      unit: (json['unit'] ?? 'g').toString(),
    );
  }
}

// Accepts num, String, or null and always returns a double. Required because
// the backend sends numeric fields as JSON strings.
double _parseDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

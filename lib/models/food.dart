import 'package:app1/config/api_config.dart';

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
  /// Placeholder shown when a food has no image of its own.
  ///
  /// This points at the backend's static placeholder
  /// (`/static/food-placeholder.png`), the SAME image the server's
  /// `services/foodImage.js` returns when no real photo is found. Building it
  /// from [ApiConfig.baseUrl] keeps the app and server in agreement on one
  /// placeholder, and keeps the URL reachable from the app's point of view
  /// (the server's own `PUBLIC_BASE_URL` may use an IP the emulator can't hit).
  ///
  /// Because this is now a network URL, it's loaded with `Image.network`. For
  /// the rare case where even this can't load (device offline), fall back to
  /// [offlineFallbackAsset], which is bundled in the app.
  static const String placeholderImage =
      '${ApiConfig.baseUrl}/static/food-placeholder.png';

  /// Bundled last-resort image used only when a network image AND the network
  /// [placeholderImage] both fail to load (e.g. the device is offline). Kept
  /// as a local asset so the UI never renders an empty box.
  static const String offlineFallbackAsset = 'assets/images/food_image.png';


  /// The `food_catalog` primary key. Always present because every search
  /// inserts into `food_catalog` first and returns the persisted row.
  final String id;

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
    required this.id,
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
  factory Food.fromCatalogJson(Map<String, dynamic> json) {
    final rawImage = json['image_url'];
    return Food(
      id: (json['id'] ?? '').toString(),
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

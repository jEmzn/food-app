import 'package:app1/config/app_theme.dart';
import 'package:app1/models/food.dart';
import 'package:app1/screens/food_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app1/services/favorites_service.dart';
import 'package:app1/widgets/top_label.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app1/widgets/categories_bar.dart';

/// One favorite entry: the [Food] (for display + navigation) plus the
/// favorite ROW id. We keep the row id around in case we later add a
/// "remove from favorites" action straight from this screen — deleting needs
/// the favorite id, not the food's catalog id.
class _FavoriteEntry {
  final Food food;
  final String favoriteId;
  const _FavoriteEntry({required this.food, required this.favoriteId});
}

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // null = still loading. Otherwise the loaded list (possibly empty).
  List<_FavoriteEntry>? _entries;

  // Holds a user-facing error message when the load fails; null otherwise.
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // Reset to the loading state so a pull-to-refresh shows progress too.
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final rows = await FavoritesService.getFavorites();
      final entries = rows.map((row) {
        // The row's `id` is the favorite id; `food_catalog_id` is the real
        // catalog id. Food.fromCatalogJson reads `id`, so we swap in the
        // catalog id there — otherwise tapping a card would open the detail
        // screen with the wrong id (breaking favorite-detection and logging).
        final foodJson = Map<String, dynamic>.from(row);
        foodJson['id'] = row['food_catalog_id'];
        return _FavoriteEntry(
          food: Food.fromCatalogJson(foodJson),
          favoriteId: (row['id'] ?? '').toString(),
        );
      }).toList();
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      // Show a friendly message; the underlying error is already localized
      // by FavoritesService, but fall back just in case.
      setState(() => _error = 'โหลดอาหารโปรดไม่สำเร็จ');
    }
  }

  // Open the detail screen for a food, then refresh on return — the user may
  // have un-favorited it there, so the list could have changed.
  Future<void> _openFood(Food food) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
    );
    if (mounted) _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: SingleChildScrollView(
        // AlwaysScrollable so pull-to-refresh works even when the list is
        // short or empty (otherwise there's nothing to drag).
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 50.0,
            bottom: 80.0,
            left: 24.0,
            right: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const TopLabel(textLabel: 'อาหารโปรด'),
              const SizedBox(height: 18),
              const CategoriesBar(),
              const SizedBox(height: 24),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  // Switch between loading / error / empty / loaded states.
  Widget _buildBody() {
    if (_error != null) {
      return _buildMessage(_error!, showRetry: true);
    }
    final entries = _entries;
    if (entries == null) {
      // Loading — give it some vertical room so the spinner isn't cramped.
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (entries.isEmpty) {
      return _buildMessage('ยังไม่มีอาหารโปรด\nกดรูปหัวใจในหน้าอาหารเพื่อเพิ่ม');
    }

    return GridView.count(
      padding: EdgeInsets.zero,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      crossAxisCount: 2,
      shrinkWrap: true,
      // The outer SingleChildScrollView handles scrolling.
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final entry in entries)
          _buildFavoriteItem(entry.food),
      ],
    );
  }

  // Centered message used for both the empty and error states.
  Widget _buildMessage(String text, {bool showRetry = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.mali(fontSize: 16, color: Colors.grey),
          ),
          if (showRetry) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadFavorites,
              child: Text(
                'ลองใหม่',
                style: GoogleFonts.mali(color: AppTheme.primaryHardColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(Food food) {
    // Pick the right Image widget — network URLs vs bundled assets.
    final url = food.imageUrl;
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    return GestureDetector(
      onTap: () => _openFood(food),
      child: Container(
        padding: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isNetwork
                ? CachedNetworkImageProvider(url) as ImageProvider
                : AssetImage(url),
            fit: BoxFit.cover,
            // If the network image fails, the box still has a color behind it.
            onError: (_, __) {},
          ),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(38, 0, 0, 0),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 50, 55, 34),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          food.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.mali(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${food.kcal.round()} kcal',
                          style: GoogleFonts.mali(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tapping the "+" also opens the detail screen, where the
                  // user can choose a serving and add it to a meal.
                  ElevatedButton(
                    onPressed: () => _openFood(food),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Text(
                      '+',
                      style: GoogleFonts.mali(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 50, 55, 34),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

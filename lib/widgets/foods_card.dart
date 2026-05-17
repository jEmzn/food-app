import 'package:app1/models/food.dart';
import 'package:app1/screens/food_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodsCard extends StatelessWidget {
  const FoodsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock list of recommended foods. Once the backend exposes a
    // /recommended endpoint we'll fetch real data here.
    final foods = <Food>[
      // Numbers are per the listed quantity+unit (e.g. "1 medium apple").
      Food(
        name: 'Apple',
        kcal: 95,
        carbsG: 25,
        proteinG: 0.5,
        fatG: 0.3,
        quantity: 1,
        unit: 'medium',
      ),
      Food(
        name: 'Banana',
        kcal: 105,
        carbsG: 27,
        proteinG: 1.3,
        fatG: 0.4,
        quantity: 1,
        unit: 'medium',
      ),
      Food(
        name: 'Orange',
        kcal: 62,
        carbsG: 15,
        proteinG: 1.2,
        fatG: 0.2,
        quantity: 1,
        unit: 'medium',
      ),
      Food(
        name: 'Orange',
        kcal: 62,
        carbsG: 15,
        proteinG: 1.2,
        fatG: 0.2,
        quantity: 1,
        unit: 'medium',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, top: 15, bottom: 15),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final food in foods)
            buildFoodsCard(
              food.imageUrl,
              food.name,
              food.kcal.round().toString(),
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FoodDetailScreen(food: food),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget buildFoodsCard(
  String imagePath,
  String title,
  String kcal,
  VoidCallback onPressed,
) {
  // Pick the right Image widget — assets and network URLs need different ones.
  final isNetwork =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');
  final image = isNetwork
      ? Image.network(
          imagePath,
          height: 220,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(Food.placeholderImage, height: 220, width: 220),
        )
      : Image.asset(imagePath, height: 220, width: 220);

  return Container(
    padding: const EdgeInsets.only(left: 10, right: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(20, 0, 0, 0),
          blurRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        minimumSize: Size(60, 60),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.all(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(38, 0, 0, 0),
                  blurRadius: 15,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Text('$kcal kcal'),
          ),
          image,
        ],
      ),
    ),
  );
}

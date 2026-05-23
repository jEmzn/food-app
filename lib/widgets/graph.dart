// import 'package:app1/screens/home_screen.dart';
import 'package:app1/config/app_theme.dart';
import 'package:app1/widgets/dashed_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: fetch data from Database
// TODO: add Backend

class GraphWidget extends StatelessWidget {
  final List<double> valueData;
  final List<String> labels;
  final int kcal;
  final int weekday;

  // Per-day macro amounts, one entry per weekday and index-aligned with
  // [labels]/[valueData]. Each inner list is [carbs, protein, fat] expressed
  // in the SAME unit (this app passes calorie contributions). The values do
  // NOT need to sum to anything — buildNutitionBar normalises them into the
  // stacked bar's shares. Pass [0, 0, 0] for a day with no food.
  final List<List<double>> macroData;

  final double sideTextHeight;
  final double sideTextSize;

  final double maxBarWidth = 35;
  final double dateLineHeight = 20;

  // static const Color primaryColor = Color(0xFFC4E145);
  // static const Color shadowColor = Color.fromARGB(38, 0, 0, 0);

  const GraphWidget({
    super.key,
    required this.valueData,
    required this.labels,
    required this.kcal,
    required this.weekday,
    required this.macroData,
    this.sideTextHeight = 16,
    this.sideTextSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max value and maxKcal for scaling,  padding of Container, total graph width for difining ScollView size
    // countLevel and levelKcal for horizontal lines
    final double maxValue = valueData.reduce((a, b) => a > b ? a : b);
    final double maxKcal = kcal * maxValue;
    final double padding = 12;
    final double heightWidget = 336;

    final double heightGraphArea =
        heightWidget - dateLineHeight - (2 * padding);

    final int countLevel = maxKcal < kcal
        ? (kcal ~/ 500) + 2
        : (maxKcal ~/ 500) + 2;
    final List<int> levelKcal = List.generate(
      countLevel,
      (index) => index * 500,
    );
    final double maxGraphLevel = levelKcal.last.toDouble();
    final double topSize = 30;
    const List<String> nutrition = ['คาร์บ', 'โปรตีน', 'ไขมัน'];
    const List<Color> nutritionColor = [
      AppTheme.macroCarbsColor,
      AppTheme.macroProteinColor,
      AppTheme.macroFatColor,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calorie Bar Graph
        Text(
          'แคลอรี (kcal)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: EdgeInsets.all(padding),
          height: heightWidget,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: heightGraphArea,
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // One label per gridline level (countLevel), not per weekday.
                  // Using labels.length here crashed when countLevel < 7 because
                  // levelKcal only has countLevel entries.
                  children: List.generate(countLevel, (index) {
                    if (index == countLevel - 1) {
                      return SizedBox(
                        height: sideTextHeight,
                        child: Text(
                          ' ',
                          style: GoogleFonts.mali(fontSize: sideTextSize),
                        ),
                      );
                    }
                    return SizedBox(
                      height: sideTextHeight,
                      child: Text(
                        levelKcal[countLevel - index - 1].toString(),
                        style: GoogleFonts.mali(fontSize: sideTextSize),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Positioned(
                      top:
                          (heightGraphArea - sideTextHeight / 2) -
                          ((kcal / maxGraphLevel) *
                              (heightGraphArea - sideTextHeight)),
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        size: Size(double.infinity, 1),
                        painter: DashedLine(),
                      ),
                    ),
                    SizedBox(
                      height: heightGraphArea,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(countLevel, (index) {
                          return SizedBox(
                            height: sideTextHeight,
                            width: double.infinity,
                            child: Divider(color: Colors.black26, thickness: 1),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: sideTextHeight / 2,
                            left: 6,
                            right: 6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(valueData.length, (index) {
                              final barHeight =
                                  ((valueData[index] * kcal) / maxGraphLevel) *
                                  (heightGraphArea - 2 * (sideTextHeight / 2));
                              return Container(
                                width: maxBarWidth,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: index + 1 == weekday
                                      ? AppTheme.primaryColor
                                      : Colors.grey.withValues(alpha: 150),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(
                          height: dateLineHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 6),
                              ...List.generate(labels.length, (index) {
                                return SizedBox(
                                  width: maxBarWidth,
                                  child: Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.mali(
                                      fontSize: sideTextSize,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text('สารอาหาร (%)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppTheme.spacingM),
        // Nutrition info
        Container(
          padding: EdgeInsets.all(padding),
          height: heightWidget,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: heightGraphArea,
                width: 40,
                child: Padding(
                  padding: EdgeInsets.only(top: topSize),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      if (4 - index == 0) {
                        return SizedBox(
                          height: sideTextHeight,
                          child: Text(
                            ' ',
                            style: GoogleFonts.mali(fontSize: sideTextSize),
                          ),
                        );
                      }
                      return SizedBox(
                        height: sideTextHeight,
                        child: Text(
                          '${(4 - index) * 25}',
                          style: GoogleFonts.mali(fontSize: sideTextSize),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    // SizedBox(
                    //   height: heightGraphArea,
                    //   child: Column(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: List.generate(countLevel, (index) {
                    //       return SizedBox(
                    //         height: sideTextHeight,
                    //         width: double.infinity,
                    //         child: Divider(color: Colors.black26, thickness: 1),
                    //       );
                    //     }),
                    //   ),
                    // ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(
                            horizontal: 32,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: List.generate(3, (index) {
                              return Container(
                                height: topSize - 6,
                                padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.shadowColor,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  spacing: 4,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: nutritionColor[index],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      nutrition[index],
                                      style: GoogleFonts.mali(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: sideTextHeight / 2,
                            left: 6,
                            right: 6,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(macroData.length, (index) {
                              final m = macroData[index];
                              return buildNutitionBar(m[0], m[1], m[2]);
                            }),
                          ),
                        ),
                        SizedBox(
                          height: dateLineHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 6),
                              ...List.generate(labels.length, (index) {
                                return SizedBox(
                                  width: maxBarWidth,
                                  child: Text(
                                    labels[index],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.mali(
                                      fontSize: sideTextSize,
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Renders one day's macro split as a full-height stacked bar (carbs on top,
  // then protein, then fat). The three inputs are amounts in any shared unit;
  // we normalise them into shares here so the segments always fill the bar.
  Widget buildNutitionBar(double carb, double protein, double fat) {
    final double padding = 12;
    final double heightWidget = 336;

    final double heightGraphArea =
        heightWidget - dateLineHeight - (2 * padding);

    final double barHeight = heightGraphArea - sideTextHeight - 30;

    final double total = carb + protein + fat;
    // No food logged that day: render an empty slot the width of a bar so the
    // weekday labels below stay aligned with the (missing) bar.
    if (total <= 0) {
      return SizedBox(width: maxBarWidth);
    }

    // Convert raw amounts into 0..1 shares of the day's total.
    final double carbShare = carb / total;
    final double proteinShare = protein / total;
    final double fatShare = fat / total;

    return Column(
      children: [
        Container(
          width: maxBarWidth,
          height: barHeight * carbShare,
          decoration: BoxDecoration(
            color: AppTheme.macroCarbsColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
        Container(
          width: maxBarWidth,
          height: barHeight * proteinShare,
          decoration: const BoxDecoration(color: AppTheme.macroProteinColor),
        ),
        Container(
          width: maxBarWidth,
          height: barHeight * fatShare,
          decoration: const BoxDecoration(color: AppTheme.macroFatColor),
        ),
      ],
    );
  }
}

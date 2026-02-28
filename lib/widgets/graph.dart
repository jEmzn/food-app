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
    const List<String> nutrition = ['carp', 'protein', 'fat'];
    const List<Color> nutritionColor = [Colors.amber, Colors.blue, Colors.red];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calorie Bar Graph
        Text(
          'Calories (kcal)',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(padding),
          height: heightWidget,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 15,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: heightGraphArea,
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(labels.length, (index) {
                    if (index == countLevel - 1) {
                      return SizedBox(
                        height: sideTextHeight,
                        child: Text(
                          ' ',
                          style: GoogleFonts.inter(fontSize: sideTextSize),
                        ),
                      );
                    }
                    return SizedBox(
                      height: sideTextHeight,
                      child: Text(
                        levelKcal[countLevel - index - 1].toString(),
                        style: GoogleFonts.inter(fontSize: sideTextSize),
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
                                    style: GoogleFonts.inter(
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
        SizedBox(height: 16),
        Text(
          'Nutrition (%)',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        // Nutrition info
        Container(
          padding: EdgeInsets.all(padding),
          height: heightWidget,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 15,
                offset: Offset(0, 0),
              ),
            ],
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
                            style: GoogleFonts.inter(fontSize: sideTextSize),
                          ),
                        );
                      }
                      return SizedBox(
                        height: sideTextHeight,
                        child: Text(
                          '${(4 - index) * 25}',
                          style: GoogleFonts.inter(fontSize: sideTextSize),
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
                                      style: GoogleFonts.inter(
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
                            children: List.generate(valueData.length, (index) {
                              return buildNutitionBar(0.5, 0.3, 0.2);
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
                                    style: GoogleFonts.inter(
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

  Widget buildNutitionBar(double carb, double protein, double fat) {
    final double padding = 12;
    final double heightWidget = 336;

    final double heightGraphArea =
        heightWidget - dateLineHeight - (2 * padding);

    final double barHeight = heightGraphArea - sideTextHeight - 30;

    if (carb + protein + fat != 1) {
      return Container();
    }
    return Column(
      children: [
        Container(
          width: maxBarWidth,
          height: barHeight * carb,
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(120),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
        Container(
          width: maxBarWidth,
          height: barHeight * protein,
          decoration: BoxDecoration(color: Colors.blue.withAlpha(120)),
        ),
        Container(
          width: maxBarWidth,
          height: barHeight * fat,
          decoration: BoxDecoration(color: Colors.red.withAlpha(120)),
        ),
      ],
    );
  }
}

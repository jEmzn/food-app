// import 'package:app1/screens/home_screen.dart';
import 'package:app1/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          height: heightWidget,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
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

        Container(),
      ],
    );
  }
}

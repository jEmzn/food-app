import 'package:flutter/material.dart';

class FlutterSalesGraph extends StatefulWidget {
  final List<double> valueData;
  final List<String> labels;
  final double maxBarHeight;
  final double barWidth;
  // final List<Color> colors;
  final Color primaryColor = const Color(0xFF73CA31);
  final Color secondsaryColor = const Color.fromARGB(255, 136, 136, 136);
  final double dateLineHeight;

  const FlutterSalesGraph({
    super.key,
    required this.valueData,
    required this.labels,
    this.maxBarHeight = 200.0,
    this.barWidth = 36.0,
    this.dateLineHeight = 20.0,
  });

  @override
  State<FlutterSalesGraph> createState() => _FlutterSalesGraphState();
}

class _FlutterSalesGraphState extends State<FlutterSalesGraph> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.valueData.isEmpty ||
        widget.labels.isEmpty ||
        widget.valueData.length != widget.labels.length) {
      return Center(child: Text('No data available or labels mismatch.'));
    }

    final double maxValue = widget.valueData.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: double.infinity),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(widget.valueData.length, (index) {
                      final sales = widget.valueData[index];
                      final label = widget.labels[index];
                      final barHeight = maxValue > 0
                          ? (sales / maxValue) * widget.maxBarHeight
                          : 2.0;
                      final color = index == 0
                          ? widget.primaryColor
                          : widget.secondsaryColor;

                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _pressedIndex = index;
                          });
                        },
                        onLongPressEnd: (_) {
                          setState(() {
                            _pressedIndex = null;
                          });
                        },
                        child: Container(
                          width: widget.barWidth,
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: widget.barWidth,
                                height: barHeight.toDouble(),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromARGB(38, 0, 0, 0),
                                      spreadRadius: 2,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (_pressedIndex == index)
                                Positioned(
                                  bottom: barHeight + 10, // Adjust as needed
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    color: Colors.black87,
                                    child: Text(
                                      '\$${sales.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: -20,
                                child: Container(
                                  width: widget.barWidth,
                                  height: widget.dateLineHeight,
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

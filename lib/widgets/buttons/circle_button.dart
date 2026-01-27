import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    this.primaryColor = Colors.black,
    required this.children,
    this.bgColor = Colors.white,
    this.fgColor = Colors.black,
    required this.onPressed,
  });

  final Color? primaryColor;
  final List<Widget> children;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? fgColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Color.fromARGB(38, 0, 0, 0),
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          minimumSize: Size(60, 60),
          shadowColor: const Color.fromARGB(90, 216, 216, 216),
          elevation: 0,
          foregroundColor: fgColor,
          shape: CircleBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: children,
        ),
      ),
    );
  }
}

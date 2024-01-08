import 'package:flutter/material.dart';

class MyCircularProgressIndicator extends StatelessWidget {
  final int count;
  final int total;
  final double width;
  final double height;

  const MyCircularProgressIndicator(
      {super.key,
      required this.count,
      required this.total,
      this.height = 40,
      this.width = 40});

  double get percentage => count.toDouble() / total.toDouble() * 100.0;

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        CircularProgressIndicator(
          value: count / total,
          backgroundColor: Colors.grey,
          color: Colors.green,
          // strokeWidth: 3,
        ),
        Center(
          child: Text(
            '${percentage.toInt()}%',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
    return SizedBox(width: width, height: height, child: Center(child: stack));
  }
}

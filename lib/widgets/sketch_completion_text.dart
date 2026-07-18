import 'package:flutter/material.dart';

class SketchCompletionText extends StatelessWidget {
  final String text;
  final bool isCompleted;
  final TextStyle style;

  const SketchCompletionText({
    super.key,
    required this.text,
    required this.isCompleted,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isCompleted ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut, // Gives it that bouncing pop
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Text(text, style: style),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 2,
            // If completed, width covers the text. If not, width is 0.
            width: isCompleted ? _getTextWidth(text, style) : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  double _getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width + 10; // Added padding for the strike
  }
}

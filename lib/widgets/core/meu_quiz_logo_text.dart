import 'package:flutter/material.dart';

class MeuQuizLogoText extends StatelessWidget {
  final double fontSize;
  final Color textColor;
  final TextAlign textAlign;

  const MeuQuizLogoText({
    super.key,
    this.fontSize = 24.0,
    this.textColor = Colors.white,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontFamily: 'Inter', // Assuming Inter or system default
        ),
        children: const [
          TextSpan(text: 'MeuQuiz'),
          TextSpan(
            text: '+',
            style: TextStyle(
              color: Colors.amber, // Cor original amarela do +
            ),
          ),
        ],
      ),
    );
  }
}

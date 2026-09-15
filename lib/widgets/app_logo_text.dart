import 'package:flutter/material.dart';

class AppLogoText extends StatelessWidget {
  final double fontSize;
  final TextAlign textAlign;

  const AppLogoText({
    super.key,
    this.fontSize = 24.0,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      text: getSpan(fontSize: fontSize),
    );
  }

  /// Returns an InlineSpan so the logo can be embedded within other RichText blocks.
  static InlineSpan getSpan({double fontSize = 24.0}) {
    final shadow = [
      Shadow(
        offset: const Offset(1.5, 1.5),
        blurRadius: 3.0,
        color: Colors.black.withValues(alpha: 0.6),
      ),
    ];

    return TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900, // Very bold / black
        letterSpacing: 0.5,
      ),
      children: [
        TextSpan(
          text: 'MEU QUIZ ',
          style: TextStyle(
            color: Colors.white,
            shadows: shadow,
          ),
        ),
        TextSpan(
          text: '+',
          style: TextStyle(
            color: const Color(0xFFFFD700), // Gold/Yellow
            shadows: shadow,
          ),
        ),
      ],
    );
  }
}

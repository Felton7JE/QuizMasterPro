import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final bool isLarge;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    final buttonHeight = isLarge 
        ? (isSmallScreen ? 48.0 : 56.0)
        : (isSmallScreen ? 40.0 : 48.0);
    
    final fontSize = isLarge 
        ? (isSmallScreen ? 14.0 : 16.0)
        : (isSmallScreen ? 12.0 : 14.0);
    
    final iconSize = isLarge 
        ? (isSmallScreen ? 18.0 : 20.0)
        : (isSmallScreen ? 16.0 : 18.0);
    
    final horizontalPadding = isLarge 
        ? (isSmallScreen ? 20.0 : 24.0)
        : (isSmallScreen ? 16.0 : 20.0);

    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF6366F1) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF6366F1),
          side: isPrimary ? null : const BorderSide(color: Color(0xFF6366F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          elevation: isPrimary ? 2 : 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize),
              SizedBox(width: isSmallScreen ? 6 : 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


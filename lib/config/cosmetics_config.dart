import 'package:flutter/material.dart';

class CosmeticsConfig {
  static const bannerGradStart = Color(0xFF7C3AED);
  static const bannerGradEnd = Color(0xFF4F46E5);
  static const phraseGradStart = Color(0xFF0EA5E9);
  static const phraseGradEnd = Color(0xFF6366F1);
  static const phraseGlow = Color(0x440EA5E9);
  
  static const List<List<Color>> _avatarColors = [
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFF06B6D4), Color(0xFF0891B2)],
    [Color(0xFFF43F5E), Color(0xFFBE123C)],
    [Color(0xFF10B981), Color(0xFF065F46)],
  ];

  static const List<List<Color>> _frameColors = [
    [Color(0xFFF97316), Color(0xFFEF4444)],
    [Color(0xFFEAB308), Color(0xFFD97706)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  /// Returns the color pair for a given avatar ID. 
  /// If id is null, returns a default neutral color.
  static List<Color> getAvatarColors(int? id) {
    if (id == null) {
      return [const Color(0xFF6366F1), const Color(0xFF4F46E5)]; // Default fallback
    }
    return _avatarColors[id % _avatarColors.length];
  }

  /// Returns the color pair for a given profile frame ID.
  /// If id is null, returns null (no frame).
  static List<Color>? getFrameColors(int? id) {
    if (id == null) return null;
    return _frameColors[id % _frameColors.length];
  }
}

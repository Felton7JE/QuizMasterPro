import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppSnackBar {
  // Cores personalizadas para combinar com o "Dark Mode" do jogo (fundo Slate)
  static const Color _bgColor = Color(0xFF1E293B);
  static const Color _textColor = Colors.white;

  static void showSuccess(BuildContext context, String message) {
    try {
      toastification.dismissAll();
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flat, // Borda lateral colorida, fundo escuro
        primaryColor: const Color(0xFF10B981), // Verde moderno/neon
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: const Text('Sucesso', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(message, style: const TextStyle(color: Colors.white70)),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
        borderRadius: BorderRadius.circular(12),
        boxShadow: highModeShadow, // Sombra mais elegante
      );
    } catch (e) {
      debugPrint('Aviso: Não foi possível mostrar SnackBar de sucesso: $e');
    }
  }

  static void showError(BuildContext context, String message) {
    try {
      toastification.dismissAll();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        primaryColor: const Color(0xFFEF4444), // Vermelho vibrante
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: const Text('Erro', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(message, style: const TextStyle(color: Colors.white70)),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
        borderRadius: BorderRadius.circular(12),
        boxShadow: highModeShadow,
      );
    } catch (e) {
      debugPrint('Aviso: Não foi possível mostrar SnackBar de erro: $e');
    }
  }

  static void showInfo(BuildContext context, String message) {
    try {
      toastification.dismissAll();
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        primaryColor: const Color(0xFF3B82F6), // Azul moderno
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: const Text('Informação', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(message, style: const TextStyle(color: Colors.white70)),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
        showProgressBar: false,
        borderRadius: BorderRadius.circular(12),
        boxShadow: highModeShadow,
      );
    } catch (e) {
      debugPrint('Aviso: Não foi possível mostrar SnackBar de info: $e');
    }
  }

  static void showWarning(BuildContext context, String message) {
    try {
      toastification.dismissAll();
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flat,
        primaryColor: const Color(0xFFF59E0B), // Laranja/Âmbar
        backgroundColor: _bgColor,
        foregroundColor: _textColor,
        title: const Text('Aviso', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(message, style: const TextStyle(color: Colors.white70)),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: false,
        borderRadius: BorderRadius.circular(12),
        boxShadow: highModeShadow,
      );
    } catch (e) {
      debugPrint('Aviso: Não foi possível mostrar SnackBar de warning: $e');
    }
  }
}

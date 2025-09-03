class ValidationUtils {
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome de usuário é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome de usuário deve ter pelo menos 3 caracteres';
    }
    if (value.trim().length > 20) {
      return 'Nome de usuário deve ter no máximo 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Nome de usuário pode conter apenas letras, números e underscore';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome completo é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome completo deve ter pelo menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'Nome completo deve ter no máximo 50 caracteres';
    }
    return null;
  }

  static String? validateRoomName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome da sala é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Nome da sala deve ter pelo menos 3 caracteres';
    }
    if (value.trim().length > 30) {
      return 'Nome da sala deve ter no máximo 30 caracteres';
    }
    return null;
  }

  static String? validateRoomPassword(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 4) {
        return 'Senha deve ter pelo menos 4 caracteres';
      }
      if (value.length > 20) {
        return 'Senha deve ter no máximo 20 caracteres';
      }
    }
    return null;
  }

  static String? validateRoomCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Código da sala é obrigatório';
    }
    if (value.trim().length != 6) {
      return 'Código da sala deve ter 6 caracteres';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.trim())) {
      return 'Código da sala deve conter apenas letras maiúsculas e números';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? validateNumericRange(
    String? value,
    String fieldName,
    int min,
    int max,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    
    final number = int.tryParse(value.trim());
    if (number == null) {
      return '$fieldName deve ser um número válido';
    }
    
    if (number < min || number > max) {
      return '$fieldName deve estar entre $min e $max';
    }
    
    return null;
  }
}

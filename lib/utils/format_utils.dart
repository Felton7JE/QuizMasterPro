import '../models/room_model.dart';

class FormatUtils {
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    } else {
      return score.toString();
    }
  }

  static String formatPercentage(double percentage, {int decimals = 1}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  static String formatAccuracy(int correctAnswers, int totalAnswers) {
    if (totalAnswers == 0) return '0%';
    final percentage = (correctAnswers / totalAnswers) * 100;
    return formatPercentage(percentage);
  }

  static String formatGameMode(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.INDIVIDUAL:
        return 'Individual';
      case GameMode.TEAM:
        return 'Em Equipe';
      case GameMode.CLASSIC:
        return 'Clássico';
    }
  }

  static String formatDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.EASY:
        return 'Fácil';
      case Difficulty.MEDIUM:
        return 'Médio';
      case Difficulty.HARD:
        return 'Difícil';
    }
  }

  static String formatTeamColor(TeamColor teamColor) {
    switch (teamColor) {
      case TeamColor.RED:
        return 'Vermelho';
      case TeamColor.BLUE:
        return 'Azul';
      case TeamColor.GREEN:
        return 'Verde';
      case TeamColor.YELLOW:
        return 'Amarelo';
    }
  }

  static String formatRoomStatus(RoomStatus status) {
    switch (status) {
      case RoomStatus.WAITING:
        return 'Aguardando';
      case RoomStatus.STARTING:
        return 'Iniciando';
      case RoomStatus.IN_PROGRESS:
        return 'Em Andamento';
      case RoomStatus.FINISHED:
        return 'Finalizado';
    }
  }

  static String formatCategory(String category) {
    switch (category.toUpperCase()) {
      case 'MATH':
        return 'Matemática';
      case 'SCIENCE':
        return 'Ciências';
      case 'GEOGRAPHY':
        return 'Geografia';
      case 'HISTORY':
        return 'História';
      case 'PORTUGUESE':
        return 'Português';
      case 'ENGLISH':
        return 'Inglês';
      case 'MIXED':
        return 'Mistas';
      default:
        return category;
    }
  }

  static String formatPlayerCount(int current, int max) {
    return '$current/$max jogadores';
  }

  static String formatQuestionProgress(int current, int total) {
    return 'Pergunta ${current + 1} de $total';
  }

  static String formatAverageTime(double averageTimeMs) {
    final seconds = averageTimeMs / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatOrdinalPosition(int position) {
    if (position == 1) return '1º';
    if (position == 2) return '2º';
    if (position == 3) return '3º';
    return '${position}º';
  }

  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

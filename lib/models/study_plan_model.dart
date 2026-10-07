import 'package:flutter/foundation.dart';

class StudyPlanDay {
  final String id;
  final int dayNumber;
  final String title;
  final String description;
  final bool isCompleted;

  const StudyPlanDay({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  StudyPlanDay copyWith({
    String? id,
    int? dayNumber,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return StudyPlanDay(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory StudyPlanDay.fromJson(Map<String, dynamic> json) {
    return StudyPlanDay(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }
}

class StudyPlan {
  final String id;
  final String topic;
  final int durationDays;
  final String objective;
  final int progressPercentage;
  final DateTime createdAt;
  final List<StudyPlanDay> days;

  const StudyPlan({
    required this.id,
    required this.topic,
    required this.durationDays,
    this.objective = '',
    this.progressPercentage = 0,
    required this.createdAt,
    this.days = const [],
  });

  StudyPlan copyWith({
    String? id,
    String? topic,
    int? durationDays,
    String? objective,
    int? progressPercentage,
    DateTime? createdAt,
    List<StudyPlanDay>? days,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      durationDays: durationDays ?? this.durationDays,
      objective: objective ?? this.objective,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt ?? this.createdAt,
      days: days ?? this.days,
    );
  }

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];

    return StudyPlan(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      topic: json['topic'] as String? ?? 'Tema de Estudo',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 5,
      objective: json['objective'] as String? ?? '',
      progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      days: rawDays
          .map((d) => StudyPlanDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'durationDays': durationDays,
      'objective': objective,
      'progressPercentage': progressPercentage,
      'createdAt': createdAt.toIso8601String(),
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}

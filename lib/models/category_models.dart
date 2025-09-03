class Category {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      displayName: json['displayName'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() => 'Category(id: $id, name: $name, displayName: $displayName, description: $description, isActive: $isActive)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// DTO para request de atribuição de categoria
class AssignCategoryRequest {
  final int playerId;
  final int categoryId;

  AssignCategoryRequest({
    required this.playerId,
    required this.categoryId,
  });

  factory AssignCategoryRequest.fromJson(Map<String, dynamic> json) {
    return AssignCategoryRequest(
      playerId: json['playerId'],
      categoryId: json['categoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'categoryId': categoryId,
    };
  }

  @override
  String toString() => 'AssignCategoryRequest(playerId: $playerId, categoryId: $categoryId)';
}

// DTO para request de distribuição automática de categorias
class DistributeCategoriesRequest {
  final int hostId;

  DistributeCategoriesRequest({
    required this.hostId,
  });

  factory DistributeCategoriesRequest.fromJson(Map<String, dynamic> json) {
    return DistributeCategoriesRequest(
      hostId: json['hostId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
    };
  }

  @override
  String toString() => 'DistributeCategoriesRequest(hostId: $hostId)';
}

// Response das estatísticas de distribuição
class CategoryDistributionStatsResponse {
  final int totalCategories;
  final int assignedCategories;
  final int unassignedCategories;
  final double assignmentPercentage;
  final bool allCategoriesAssigned;
  final Map<String, CategoryStats> categoryStats;

  CategoryDistributionStatsResponse({
    required this.totalCategories,
    required this.assignedCategories,
    required this.unassignedCategories,
    required this.assignmentPercentage,
    required this.allCategoriesAssigned,
    required this.categoryStats,
  });

  factory CategoryDistributionStatsResponse.fromJson(Map<String, dynamic> json) {
    Map<String, CategoryStats> stats = {};
    if (json['categoryStats'] != null) {
      (json['categoryStats'] as Map<String, dynamic>).forEach((key, value) {
        stats[key] = CategoryStats.fromJson(value);
      });
    }

    return CategoryDistributionStatsResponse(
      totalCategories: json['totalCategories'] ?? 0,
      assignedCategories: json['assignedCategories'] ?? 0,
      unassignedCategories: json['unassignedCategories'] ?? 0,
      assignmentPercentage: (json['assignmentPercentage'] ?? 0.0).toDouble(),
      allCategoriesAssigned: json['allCategoriesAssigned'] ?? false,
      categoryStats: stats,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> statsMap = {};
    categoryStats.forEach((key, value) {
      statsMap[key] = value.toJson();
    });

    return {
      'totalCategories': totalCategories,
      'assignedCategories': assignedCategories,
      'unassignedCategories': unassignedCategories,
      'assignmentPercentage': assignmentPercentage,
      'allCategoriesAssigned': allCategoriesAssigned,
      'categoryStats': statsMap,
    };
  }

  @override
  String toString() => 'CategoryDistributionStatsResponse(totalCategories: $totalCategories, assignedCategories: $assignedCategories, unassignedCategories: $unassignedCategories, assignmentPercentage: $assignmentPercentage, allCategoriesAssigned: $allCategoriesAssigned)';
}

class CategoryStats {
  final int assignedCount;
  final List<String> assignedPlayerNames;

  CategoryStats({
    required this.assignedCount,
    required this.assignedPlayerNames,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      assignedCount: json['assignedCount'] ?? 0,
      assignedPlayerNames: List<String>.from(json['assignedPlayerNames'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignedCount': assignedCount,
      'assignedPlayerNames': assignedPlayerNames,
    };
  }

  @override
  String toString() => 'CategoryStats(assignedCount: $assignedCount, assignedPlayerNames: $assignedPlayerNames)';
}

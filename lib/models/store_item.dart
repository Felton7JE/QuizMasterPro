import 'package:flutter/foundation.dart';

@immutable
class StoreItem {
  final int id;
  final String name;
  final String description;
  final int price;
  final String type; // 'BANNER', 'TEXT_PHRASE', 'AVATAR', 'PROFILE_FRAME', 'ENERGY_REFILL', 'XP_BOOST'
  final String value;
  final String rarity;
  final bool isEquipped;
  
  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.value,
    required this.rarity,
    this.isEquipped = false,
  });

  StoreItem copyWith({
    int? id,
    String? name,
    String? description,
    int? price,
    String? type,
    String? value,
    String? rarity,
    bool? isEquipped,
  }) {
    return StoreItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      value: value ?? this.value,
      rarity: rarity ?? this.rarity,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      type: json['type'] as String,
      value: json['value'] as String,
      rarity: json['rarity'] as String? ?? 'Comum',
      isEquipped: (json['isEquipped'] as bool?) ?? false,
    );
  }

  /// Dois StoreItems são iguais se tiverem o mesmo [id].
  /// Necessário para que List.contains(), any(), etc. funcionem
  /// correctamente com objectos criados em chamadas API distintas.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString() => 'StoreItem(id: $id, name: $name, type: $type, isEquipped: $isEquipped)';
}

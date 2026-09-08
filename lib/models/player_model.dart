import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Player model representing a game participant
class Player {
  final String id;
  final String name;
  final Color avatarColor;
  final DateTime createdAt;

  Player({
    String? id,
    required this.name,
    Color? avatarColor,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       avatarColor = avatarColor ?? _getColorForName(name),
       createdAt = createdAt ?? DateTime.now();

  /// Get a deterministic color based on player name
  static Color _getColorForName(String name) {
    const colors = [
      Color(0xFFC17F3E), // amber
      Color(0xFF2F5D4F), // felt
      Color(0xFFD3654B), // coral
      Color(0xFF9AA0A6), // silver
      Color(0xFFB57A4E), // bronze
      Color(0xFFD8A73D), // gold
    ];

    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Copy with modifications
  Player copyWith({
    String? id,
    String? name,
    Color? avatarColor,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarColor': avatarColor.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarColor: Color(json['avatarColor'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() => 'Player(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

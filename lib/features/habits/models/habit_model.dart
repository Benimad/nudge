import 'package:uuid/uuid.dart';

class HabitModel {
  final String id;
  final String name;
  final String timeOfDay;
  final String reminderStyle;
  final bool isActive;
  final DateTime createdAt;
  final String color;
  final String emoji;
  final bool aiBreakdownEnabled;
  final int habitOrder;

  HabitModel({
    String? id,
    required this.name,
    required this.timeOfDay,
    required this.reminderStyle,
    this.isActive = true,
    DateTime? createdAt,
    required this.color,
    required this.emoji,
    this.aiBreakdownEnabled = true,
    this.habitOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timeOfDay': timeOfDay,
      'reminderStyle': reminderStyle,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'color': color,
      'emoji': emoji,
      'aiBreakdownEnabled': aiBreakdownEnabled ? 1 : 0,
      'habit_order': habitOrder,
    };
  }

  HabitModel copyWith({
    String? name,
    String? timeOfDay,
    String? reminderStyle,
    bool? isActive,
    String? color,
    String? emoji,
    bool? aiBreakdownEnabled,
    int? habitOrder,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      color: color ?? this.color,
      emoji: emoji ?? this.emoji,
      aiBreakdownEnabled: aiBreakdownEnabled ?? this.aiBreakdownEnabled,
      habitOrder: habitOrder ?? this.habitOrder,
    );
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'],
      name: map['name'],
      timeOfDay: map['timeOfDay'],
      reminderStyle: map['reminderStyle'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      color: map['color'],
      emoji: map['emoji'],
      aiBreakdownEnabled: map['aiBreakdownEnabled'] == 1,
      habitOrder: map['habit_order'] ?? 0,
    );
  }
}

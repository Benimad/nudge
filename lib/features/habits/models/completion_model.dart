import 'package:uuid/uuid.dart';

class CompletionModel {
  final String id;
  final String habitId;
  final DateTime completedAt;
  final String? note;
  final int? moodScore;

  CompletionModel({
    String? id,
    required this.habitId,
    DateTime? completedAt,
    this.note,
    this.moodScore,
  })  : id = id ?? const Uuid().v4(),
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'completedAt': completedAt.toIso8601String(),
      'note': note,
      'moodScore': moodScore,
    };
  }

  factory CompletionModel.fromMap(Map<String, dynamic> map) {
    return CompletionModel(
      id: map['id'],
      habitId: map['habitId'],
      completedAt: DateTime.parse(map['completedAt']),
      note: map['note'],
      moodScore: map['moodScore'],
    );
  }
}

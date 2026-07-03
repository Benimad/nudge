class UserProfile {
  final String id;
  final String displayName;
  final String brainType;
  final bool isPremium;
  final int totalDopaminePoints;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.brainType,
    this.isPremium = false,
    this.totalDopaminePoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'brainType': brainType,
      'isPremium': isPremium ? 1 : 0,
      'totalDopaminePoints': totalDopaminePoints,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'Nudger',
      brainType: map['brainType'] ?? 'Not specified',
      isPremium: map['isPremium'] == 1,
      totalDopaminePoints: map['totalDopaminePoints'] ?? 0,
    );
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? brainType,
    bool? isPremium,
    int? totalDopaminePoints,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      brainType: brainType ?? this.brainType,
      isPremium: isPremium ?? this.isPremium,
      totalDopaminePoints: totalDopaminePoints ?? this.totalDopaminePoints,
    );
  }
}

enum BrainType { adhd, autism, anxiety, neurotypical, notSure, combined }

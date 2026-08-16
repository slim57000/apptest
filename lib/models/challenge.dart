class Challenge {
  final String id;
  final String name;
  final String emoji;
  final String inviteCode;
  final String createdBy;

  const Challenge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.inviteCode,
    required this.createdBy,
  });

  factory Challenge.fromRow(Map<String, dynamic> row) {
    return Challenge(
      id: row['id'] as String,
      name: row['name'] as String,
      emoji: row['emoji'] as String,
      inviteCode: row['invite_code'] as String,
      createdBy: row['created_by'] as String,
    );
  }
}

class ChallengeMemberStatus {
  final String userId;
  final String displayName;
  final bool doneToday;
  final int streak;

  const ChallengeMemberStatus({
    required this.userId,
    required this.displayName,
    required this.doneToday,
    required this.streak,
  });
}

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy, // Remove 1 specific block
  medium, // Remove 2 blocks in sequence
  hard, // Remove blocks with specific constraints
}

/// Challenge status
enum ChallengeStatus {
  inactive, // Not active
  active, // Currently active
  completed, // Successfully completed
  failed, // Tower collapsed or time ran out
  skipped, // Player skipped it
}

/// Represents a single challenge
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final int rewardPoints;
  final int timeLimit; // in seconds, 0 = no limit
  final ChallengeType type;
  final Map<String, dynamic> constraints; // Type-specific constraints

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.rewardPoints,
    required this.timeLimit,
    required this.type,
    required this.constraints,
  });

  /// Factory constructors for specific challenge types
  factory Challenge.removeSpecificBlock({
    required int blockLayer,
    required int blockPosition,
  }) {
    return Challenge(
      id: 'challenge_block_${blockLayer}_$blockPosition',
      title: 'Precision Strike',
      description:
          'Remove the block from layer $blockLayer, position $blockPosition',
      difficulty: ChallengeDifficulty.easy,
      rewardPoints: 15,
      timeLimit: 30,
      type: ChallengeType.removeSpecific,
      constraints: {'layer': blockLayer, 'position': blockPosition},
    );
  }

  factory Challenge.removeSequence({
    required List<Map<String, int>> blockSequence,
  }) {
    return Challenge(
      id: 'challenge_sequence_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Block Chain',
      description: 'Remove ${blockSequence.length} blocks in the correct order',
      difficulty: ChallengeDifficulty.medium,
      rewardPoints: 25,
      timeLimit: 60,
      type: ChallengeType.removeSequence,
      constraints: {'sequence': blockSequence},
    );
  }

  factory Challenge.customConstraint({
    required String title,
    required String description,
    required ChallengeDifficulty difficulty,
    required Map<String, dynamic> constraints,
  }) {
    return Challenge(
      id: 'challenge_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      difficulty: difficulty,
      rewardPoints: _getRewardByDifficulty(difficulty),
      timeLimit: _getTimeLimitByDifficulty(difficulty),
      type: ChallengeType.custom,
      constraints: constraints,
    );
  }

  static int _getRewardByDifficulty(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 15;
      case ChallengeDifficulty.medium:
        return 25;
      case ChallengeDifficulty.hard:
        return 40;
    }
  }

  static int _getTimeLimitByDifficulty(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 30;
      case ChallengeDifficulty.medium:
        return 60;
      case ChallengeDifficulty.hard:
        return 90;
    }
  }
}

/// Types of challenges
enum ChallengeType {
  removeSpecific, // Remove a specific block
  removeSequence, // Remove blocks in order
  timeLimit, // Complete within time
  blockLimit, // Complete with limited block removals
  layerSpecific, // Only from specific layers
  custom, // Custom challenge
}

/// Challenge state tracking
class ChallengeProgress {
  final Challenge challenge;
  final ChallengeStatus status;
  final int blocksRemoved;
  final int blocksRequired;
  final DateTime startTime;
  final DateTime? completedTime;
  final int timeRemainingSeconds;

  ChallengeProgress({
    required this.challenge,
    required this.status,
    required this.blocksRemoved,
    required this.blocksRequired,
    required this.startTime,
    this.completedTime,
    required this.timeRemainingSeconds,
  });

  /// Check if challenge is completed
  bool get isCompleted =>
      status == ChallengeStatus.completed ||
      status == ChallengeStatus.failed ||
      status == ChallengeStatus.skipped;

  /// Get progress percentage
  double get progressPercent =>
      blocksRequired > 0 ? (blocksRemoved / blocksRequired).clamp(0, 1) : 0;

  /// Copy with modifications
  ChallengeProgress copyWith({
    Challenge? challenge,
    ChallengeStatus? status,
    int? blocksRemoved,
    int? blocksRequired,
    DateTime? startTime,
    DateTime? completedTime,
    int? timeRemainingSeconds,
  }) {
    return ChallengeProgress(
      challenge: challenge ?? this.challenge,
      status: status ?? this.status,
      blocksRemoved: blocksRemoved ?? this.blocksRemoved,
      blocksRequired: blocksRequired ?? this.blocksRequired,
      startTime: startTime ?? this.startTime,
      completedTime: completedTime ?? this.completedTime,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    );
  }
}

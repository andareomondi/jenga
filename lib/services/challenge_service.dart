import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/models/challenge_model.dart';

/// Service for managing game challenges
class ChallengeService {
  static final ChallengeService _instance = ChallengeService._internal();

  factory ChallengeService() {
    return _instance;
  }

  ChallengeService._internal();

  final Random _random = Random();
  int _challengeFrequency = 3; // Every 3rd turn triggers challenge check

  /// Set challenge frequency (every N turns)
  void setChallengeFrequency(int frequency) {
    _challengeFrequency = frequency;
    debugPrint('[Challenge] Frequency set to every $frequency turns');
  }

  /// Check if a challenge should be triggered
  /// Returns true if current turn count is divisible by frequency
  bool shouldTriggerChallenge(int totalTurnCount) {
    if (totalTurnCount <= 0) return false;
    final shouldTrigger = totalTurnCount % _challengeFrequency == 0;
    debugPrint(
      '[Challenge] Turn $totalTurnCount - Should trigger: $shouldTrigger',
    );
    return shouldTrigger;
  }

  /// Generate a random challenge for the current player
  Challenge generateRandomChallenge({
    required int currentTowerBlockCount,
    required int intactLayers,
  }) {
    final difficulty = _selectRandomDifficulty();
    debugPrint('[Challenge] Generating $difficulty challenge');

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return _generateEasyChallenge(currentTowerBlockCount, intactLayers);
      case ChallengeDifficulty.medium:
        return _generateMediumChallenge(currentTowerBlockCount, intactLayers);
      case ChallengeDifficulty.hard:
        return _generateHardChallenge(currentTowerBlockCount, intactLayers);
    }
  }

  /// Generate easy challenge (remove specific block)
  Challenge _generateEasyChallenge(int blockCount, int intactLayers) {
    if (intactLayers <= 0 || blockCount <= 0) {
      return _generateFallbackChallenge();
    }

    // Pick random layer from intact layers
    final layer = _random.nextInt(intactLayers);
    final position = _random.nextInt(3); // 0, 1, 2

    debugPrint(
      '[Challenge] Easy: Remove block from layer $layer, position $position',
    );

    return Challenge.removeSpecificBlock(
      blockLayer: layer,
      blockPosition: position,
    );
  }

  /// Generate medium challenge (remove sequence of blocks)
  Challenge _generateMediumChallenge(int blockCount, int intactLayers) {
    if (intactLayers <= 1 || blockCount <= 2) {
      return _generateFallbackChallenge();
    }

    // Generate sequence of 2-3 blocks
    final sequenceLength = 2 + _random.nextInt(2); // 2 or 3
    final sequence = <Map<String, int>>[];

    for (int i = 0; i < sequenceLength; i++) {
      final layer = _random.nextInt(intactLayers);
      final position = _random.nextInt(3);
      sequence.add({'layer': layer, 'position': position});
    }

    debugPrint('[Challenge] Medium: Sequence of $sequenceLength blocks');

    return Challenge.removeSequence(blockSequence: sequence);
  }

  /// Generate hard challenge (complex constraint)
  Challenge _generateHardChallenge(int blockCount, int intactLayers) {
    if (intactLayers <= 1 || blockCount <= 3) {
      return _generateFallbackChallenge();
    }

    // Random hard challenge type
    final hardType = _random.nextInt(3);

    switch (hardType) {
      case 0:
        // Remove from specific layer only
        final layer = _random.nextInt(intactLayers);
        return Challenge.customConstraint(
          title: 'Layer Lock',
          description: 'Remove a block only from layer $layer',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'allowedLayer': layer},
        );

      case 1:
        // Remove blocks with alternating pattern
        return Challenge.customConstraint(
          title: 'Alternating Pattern',
          description:
              'Remove blocks alternating between top and bottom layers',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'pattern': 'alternating', 'count': 2},
        );

      default:
        // Time pressure challenge
        return Challenge.customConstraint(
          title: 'Quick Hands',
          description: 'Remove 2 blocks in under 20 seconds!',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'timeLimit': 20, 'blockCount': 2},
        );
    }
  }

  /// Fallback challenge when tower state makes normal challenge impossible
  Challenge _generateFallbackChallenge() {
    return Challenge.customConstraint(
      title: 'Steady Hand',
      description: 'Remove 1 block carefully',
      difficulty: ChallengeDifficulty.easy,
      constraints: {'blockCount': 1},
    );
  }

  /// Select random difficulty (weighted towards easier)
  ChallengeDifficulty _selectRandomDifficulty() {
    final rand = _random.nextDouble();

    if (rand < 0.5) {
      return ChallengeDifficulty.easy;
    } else if (rand < 0.8) {
      return ChallengeDifficulty.medium;
    } else {
      return ChallengeDifficulty.hard;
    }
  }

  /// Validate if a block removal satisfies a specific challenge
  bool validateBlockRemoval(
    Challenge challenge,
    int removedLayer,
    int removedPosition,
  ) {
    switch (challenge.type) {
      case ChallengeType.removeSpecific:
        final requiredLayer = challenge.constraints['layer'] as int;
        final requiredPosition = challenge.constraints['position'] as int;
        return removedLayer == requiredLayer &&
            removedPosition == requiredPosition;

      case ChallengeType.removeSequence:
        // This is handled by ChallengeProgress tracking
        return true;

      case ChallengeType.timeLimit:
        return true;

      case ChallengeType.blockLimit:
        return true;

      case ChallengeType.layerSpecific:
        final allowedLayer = challenge.constraints['allowedLayer'] as int;
        return removedLayer == allowedLayer;

      case ChallengeType.custom:
        // Custom validation logic
        if (challenge.title.contains('Steady Hand')) {
          return true; // Always passes
        }
        return true;
    }
  }

  /// Validate tower event against active challenge
  bool validateChallengeProgress(ChallengeProgress progress, TowerEvent event) {
    if (event.type != TowerEventType.removed) {
      return false; // Only block removals count
    }

    // Check time limit
    if (progress.challenge.timeLimit > 0) {
      if (progress.timeRemainingSeconds <= 0) {
        return false; // Time's up
      }
    }

    return true;
  }

  /// Check if challenge is completed based on progress
  bool isChallengeCompleted(ChallengeProgress progress) {
    return progress.blocksRemoved >= progress.blocksRequired;
  }

  /// Calculate reward points for completed challenge
  int calculateReward(
    Challenge challenge, {
    required bool onFirstAttempt,
    required int timeRemainingSeconds,
  }) {
    int baseReward = challenge.rewardPoints;

    // Bonus for time remaining
    if (challenge.timeLimit > 0 && timeRemainingSeconds > 0) {
      final timeBonus = (timeRemainingSeconds / challenge.timeLimit * 10)
          .toInt();
      baseReward += timeBonus;
    }

    // Bonus for first attempt
    if (onFirstAttempt) {
      baseReward = (baseReward * 1.5).toInt();
    }

    debugPrint(
      '[Challenge] Reward: $baseReward (base: ${challenge.rewardPoints})',
    );

    return baseReward;
  }

  /// Get challenge difficulty description
  static String getDifficultyLabel(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
    }
  }

  /// Get challenge difficulty color (for UI)
  static String getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return '#2F5D4F'; // felt (green)
      case ChallengeDifficulty.medium:
        return '#C17F3E'; // amber
      case ChallengeDifficulty.hard:
        return '#D3654B'; // coral (red)
    }
  }

  /// Get challenge emoji icon
  static String getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.removeSpecific:
        return '🎯';
      case ChallengeType.removeSequence:
        return '⛓️';
      case ChallengeType.timeLimit:
        return '⏱️';
      case ChallengeType.blockLimit:
        return '🚫';
      case ChallengeType.layerSpecific:
        return '📍';
      case ChallengeType.custom:
        return '⚡';
    }
  }
}

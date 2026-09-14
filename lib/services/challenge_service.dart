import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:jenga/models/tower_event.dart';
import 'package:jenga/models/challenge_model.dart';

/// Service for managing game challenges without spatial/layer constraints
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
  bool shouldTriggerChallenge(int totalTurnCount) {
    if (totalTurnCount <= 0) return false;
    final shouldTrigger = totalTurnCount % _challengeFrequency == 0;
    debugPrint(
      '[Challenge] Turn $totalTurnCount - Should trigger: $shouldTrigger',
    );
    return shouldTrigger;
  }

  /// Generate a random challenge for the current player
  Challenge generateRandomChallenge({required int currentTowerBlockCount}) {
    final difficulty = _selectRandomDifficulty();
    debugPrint('[Challenge] Generating $difficulty challenge');

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return _generateEasyChallenge(currentTowerBlockCount);
      case ChallengeDifficulty.medium:
        return _generateMediumChallenge(currentTowerBlockCount);
      case ChallengeDifficulty.hard:
        return _generateHardChallenge(currentTowerBlockCount);
    }
  }

  /// Generate easy challenge (physical posture or generous timer)
  Challenge _generateEasyChallenge(int blockCount) {
    final easyType = _random.nextInt(3);

    switch (easyType) {
      case 0:
        return Challenge.customConstraint(
          title: 'Off-Hand Touch',
          description: 'Remove 1 block using only your non-dominant hand!',
          difficulty: ChallengeDifficulty.easy,
          constraints: {'blockCount': 1},
        );
      case 1:
        return Challenge.customConstraint(
          title: 'Two-Finger Pinch',
          description: 'Remove 1 block using only your thumb and index finger!',
          difficulty: ChallengeDifficulty.easy,
          constraints: {'blockCount': 1},
        );
      default:
        return Challenge.customConstraint(
          title: 'Steady Rhythm',
          description: 'Remove 1 block within 30 seconds',
          difficulty: ChallengeDifficulty.easy,
          constraints: {'timeLimit': 30, 'blockCount': 1},
        );
    }
  }

  /// Generate medium challenge (moderate time limit or multi-block)
  Challenge _generateMediumChallenge(int blockCount) {
    final mediumType = _random.nextInt(3);

    switch (mediumType) {
      case 0:
        return Challenge.customConstraint(
          title: 'Speed Pull',
          description: 'Remove 1 block in under 15 seconds!',
          difficulty: ChallengeDifficulty.medium,
          constraints: {'timeLimit': 15, 'blockCount': 1},
        );
      case 1:
        return Challenge.customConstraint(
          title: 'Double Trouble',
          description: 'Successfully remove 2 blocks during this turn!',
          difficulty: ChallengeDifficulty.medium,
          constraints: {'blockCount': 2},
        );
      default:
        return Challenge.customConstraint(
          title: 'One Finger Push',
          description: 'Push a block out using only ONE finger!',
          difficulty: ChallengeDifficulty.medium,
          constraints: {'blockCount': 1},
        );
    }
  }

  /// Generate hard challenge (strict time limits or speed double removal)
  Challenge _generateHardChallenge(int blockCount) {
    final hardType = _random.nextInt(3);

    switch (hardType) {
      case 0:
        return Challenge.customConstraint(
          title: 'Lightning Reflexes',
          description: 'Remove 1 block in under 8 seconds!',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'timeLimit': 8, 'blockCount': 1},
        );
      case 1:
        return Challenge.customConstraint(
          title: 'Rapid Double',
          description: 'Remove 2 blocks in under 20 seconds!',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'timeLimit': 20, 'blockCount': 2},
        );
      default:
        return Challenge.customConstraint(
          title: 'Off-Hand Sprint',
          description:
              'Remove 1 block in under 10 seconds using ONLY your non-dominant hand!',
          difficulty: ChallengeDifficulty.hard,
          constraints: {'timeLimit': 10, 'blockCount': 1},
        );
    }
  }

  /// Fallback challenge when conditions are edge-cases
  Challenge generateFallbackChallenge() {
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

  /// Validate challenge state on incoming tower events
  bool validateChallengeProgress(ChallengeProgress progress, TowerEvent event) {
    if (event.type != TowerEventType.removed) {
      return false; // Only block removals count
    }

    // Check time limit
    if (progress.challenge.timeLimit > 0) {
      if (progress.timeRemainingSeconds <= 0) {
        return false; // Time expired
      }
    }

    return true;
  }

  /// Check if challenge requirement is satisfied
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

    // Time bonus
    if (challenge.timeLimit > 0 && timeRemainingSeconds > 0) {
      final timeBonus = (timeRemainingSeconds / challenge.timeLimit * 10)
          .toInt();
      baseReward += timeBonus;
    }

    // First attempt multiplier
    if (onFirstAttempt) {
      baseReward = (baseReward * 1.5).toInt();
    }

    debugPrint(
      '[Challenge] Reward: $baseReward (base: ${challenge.rewardPoints})',
    );

    return baseReward;
  }

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

  static String getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return '#2F5D4F';
      case ChallengeDifficulty.medium:
        return '#C17F3E';
      case ChallengeDifficulty.hard:
        return '#D3654B';
    }
  }

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

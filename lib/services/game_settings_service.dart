import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing all game settings and constraints with persistent storage
class GameSettingsService {
  static final GameSettingsService _instance = GameSettingsService._internal();

  factory GameSettingsService() {
    return _instance;
  }

  GameSettingsService._internal();

  late SharedPreferences _prefs;

  // Storage keys
  static const String _maxBlocksKey = 'game_max_blocks';
  static const String _minPlayersKey = 'game_min_players';
  static const String _maxPlayersKey = 'game_max_players';
  static const String _challengeFrequencyKey = 'game_challenge_frequency';
  static const String _minBlocksForGameKey = 'game_min_blocks_for_start';
  static const String _unstableThresholdKey = 'game_unstable_threshold';
  static const String _blockCollapseDeltaKey = 'game_block_collapse_delta';
  static const String _baseBockRemovalPointsKey =
      'game_base_block_removal_points';
  static const String _easyRewardPointsKey = 'game_easy_reward_points';
  static const String _mediumRewardPointsKey = 'game_medium_reward_points';
  static const String _hardRewardPointsKey = 'game_hard_reward_points';

  // Default values
  static const int defaultMaxBlocks = 54;
  static const int defaultMinPlayers = 2;
  static const int defaultMaxPlayers = 6;
  static const int defaultChallengeFrequency = 3; // Every 3rd turn
  static const int defaultMinBlocksForGame = 6;
  static const double defaultUnstableThreshold = 0.2; // 20% of max blocks
  static const int defaultBlockCollapseDelta = 3; // 3+ blocks = collapse
  static const int defaultBaseBlockRemovalPoints = 10;
  static const int defaultEasyRewardPoints = 15;
  static const int defaultMediumRewardPoints = 25;
  static const int defaultHardRewardPoints = 40;

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('[Settings] Service initialized');
    } catch (e) {
      debugPrint('[Settings] Error initializing: $e');
      rethrow;
    }
  }

  // ============================================
  // BLOCK SETTINGS
  // ============================================

  int getMaxBlocks() => _prefs.getInt(_maxBlocksKey) ?? defaultMaxBlocks;

  Future<void> setMaxBlocks(int value) async {
    if (value < 10 || value > 100) {
      throw Exception('Max blocks must be between 10 and 100');
    }
    await _prefs.setInt(_maxBlocksKey, value);
    debugPrint('[Settings] Max blocks set to $value');
  }

  // ============================================
  // PLAYER SETTINGS
  // ============================================

  int getMinPlayers() => _prefs.getInt(_minPlayersKey) ?? defaultMinPlayers;

  Future<void> setMinPlayers(int value) async {
    if (value < 1 || value > 10) {
      throw Exception('Min players must be between 1 and 10');
    }
    if (value > getMaxPlayers()) {
      throw Exception('Min players cannot exceed max players');
    }
    await _prefs.setInt(_minPlayersKey, value);
    debugPrint('[Settings] Min players set to $value');
  }

  int getMaxPlayers() => _prefs.getInt(_maxPlayersKey) ?? defaultMaxPlayers;

  Future<void> setMaxPlayers(int value) async {
    if (value < 1 || value > 10) {
      throw Exception('Max players must be between 1 and 10');
    }
    if (value < getMinPlayers()) {
      throw Exception('Max players cannot be less than min players');
    }
    await _prefs.setInt(_maxPlayersKey, value);
    debugPrint('[Settings] Max players set to $value');
  }

  // ============================================
  // CHALLENGE SETTINGS
  // ============================================

  int getChallengeFrequency() =>
      _prefs.getInt(_challengeFrequencyKey) ?? defaultChallengeFrequency;

  Future<void> setChallengeFrequency(int value) async {
    if (value < 1 || value > 10) {
      throw Exception('Challenge frequency must be between 1 and 10');
    }
    await _prefs.setInt(_challengeFrequencyKey, value);
    debugPrint('[Settings] Challenge frequency set to every $value turns');
  }

  // ============================================
  // GAME STATE SETTINGS
  // ============================================

  int getMinBlocksForGame() =>
      _prefs.getInt(_minBlocksForGameKey) ?? defaultMinBlocksForGame;

  Future<void> setMinBlocksForGame(int value) async {
    if (value < 3 || value > 20) {
      throw Exception('Min blocks for game must be between 3 and 20');
    }
    await _prefs.setInt(_minBlocksForGameKey, value);
    debugPrint('[Settings] Min blocks for game set to $value');
  }

  double getUnstableThreshold() =>
      _prefs.getDouble(_unstableThresholdKey) ?? defaultUnstableThreshold;

  Future<void> setUnstableThreshold(double value) async {
    if (value < 0.1 || value > 0.5) {
      throw Exception(
        'Unstable threshold must be between 0.1 and 0.5 (10%-50%)',
      );
    }
    await _prefs.setDouble(_unstableThresholdKey, value);
    debugPrint(
      '[Settings] Unstable threshold set to ${(value * 100).toInt()}%',
    );
  }

  int getBlockCollapseDelta() =>
      _prefs.getInt(_blockCollapseDeltaKey) ?? defaultBlockCollapseDelta;

  Future<void> setBlockCollapseDelta(int value) async {
    if (value < 1 || value > 10) {
      throw Exception('Block collapse delta must be between 1 and 10');
    }
    await _prefs.setInt(_blockCollapseDeltaKey, value);
    debugPrint('[Settings] Block collapse delta set to $value blocks');
  }

  // ============================================
  // REWARD SETTINGS
  // ============================================

  int getBaseBlockRemovalPoints() =>
      _prefs.getInt(_baseBockRemovalPointsKey) ?? defaultBaseBlockRemovalPoints;

  Future<void> setBaseBlockRemovalPoints(int value) async {
    if (value < 1 || value > 50) {
      throw Exception('Base block removal points must be between 1 and 50');
    }
    await _prefs.setInt(_baseBockRemovalPointsKey, value);
    debugPrint('[Settings] Base block removal points set to $value');
  }

  int getEasyRewardPoints() =>
      _prefs.getInt(_easyRewardPointsKey) ?? defaultEasyRewardPoints;

  Future<void> setEasyRewardPoints(int value) async {
    if (value < 5 || value > 50) {
      throw Exception('Easy reward points must be between 5 and 50');
    }
    await _prefs.setInt(_easyRewardPointsKey, value);
    debugPrint('[Settings] Easy reward points set to $value');
  }

  int getMediumRewardPoints() =>
      _prefs.getInt(_mediumRewardPointsKey) ?? defaultMediumRewardPoints;

  Future<void> setMediumRewardPoints(int value) async {
    if (value < 5 || value > 50) {
      throw Exception('Medium reward points must be between 5 and 50');
    }
    await _prefs.setInt(_mediumRewardPointsKey, value);
    debugPrint('[Settings] Medium reward points set to $value');
  }

  int getHardRewardPoints() =>
      _prefs.getInt(_hardRewardPointsKey) ?? defaultHardRewardPoints;

  Future<void> setHardRewardPoints(int value) async {
    if (value < 5 || value > 100) {
      throw Exception('Hard reward points must be between 5 and 100');
    }
    await _prefs.setInt(_hardRewardPointsKey, value);
    debugPrint('[Settings] Hard reward points set to $value');
  }

  // ============================================
  // RESET SETTINGS
  // ============================================

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      await _prefs.remove(_maxBlocksKey);
      await _prefs.remove(_minPlayersKey);
      await _prefs.remove(_maxPlayersKey);
      await _prefs.remove(_challengeFrequencyKey);
      await _prefs.remove(_minBlocksForGameKey);
      await _prefs.remove(_unstableThresholdKey);
      await _prefs.remove(_blockCollapseDeltaKey);
      await _prefs.remove(_baseBockRemovalPointsKey);
      await _prefs.remove(_easyRewardPointsKey);
      await _prefs.remove(_mediumRewardPointsKey);
      await _prefs.remove(_hardRewardPointsKey);
      debugPrint('[Settings] All settings reset to defaults');
    } catch (e) {
      debugPrint('[Settings] Error resetting to defaults: $e');
      rethrow;
    }
  }

  /// Get all current settings as a map (useful for debugging/exporting)
  Map<String, dynamic> getAllSettings() {
    return {
      'maxBlocks': getMaxBlocks(),
      'minPlayers': getMinPlayers(),
      'maxPlayers': getMaxPlayers(),
      'challengeFrequency': getChallengeFrequency(),
      'minBlocksForGame': getMinBlocksForGame(),
      'unstableThreshold': getUnstableThreshold(),
      'blockCollapseDelta': getBlockCollapseDelta(),
      'baseBlockRemovalPoints': getBaseBlockRemovalPoints(),
      'easyRewardPoints': getEasyRewardPoints(),
      'mediumRewardPoints': getMediumRewardPoints(),
      'hardRewardPoints': getHardRewardPoints(),
    };
  }
}
